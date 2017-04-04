//
//  PINRemoteImageManager.m
//  Pods
//
//  Created by Garrett Moon on 8/17/14.
//
//

#import "PINRemoteImageManager.h"

#import <CommonCrypto/CommonDigest.h>
#import <PINOperation/PINOperation.h>

#import "PINAlternateRepresentationProvider.h"
#import "PINRemoteImage.h"
#import "PINRemoteLock.h"
#import "PINProgressiveImage.h"
#import "PINRemoteImageCallbacks.h"
#import "PINRemoteImageTask.h"
#import "PINRemoteImageProcessorTask.h"
#import "PINRemoteImageDownloadTask.h"
#import "PINResume.h"
#import "PINURLSessionManager.h"
#import "PINRemoteImageMemoryContainer.h"
#import "PINRemoteImageCaching.h"
#import "PINRemoteImageDownloadQueue.h"

#import "NSData+ImageDetectors.h"
#import "PINImage+DecodedImage.h"
#import "PINImage+ScaledImage.h"

#if USE_PINCACHE
#import "PINCache+PINRemoteImageCaching.h"
#else
#import "PINRemoteImageBasicCache.h"
#endif


#define PINRemoteImageManagerDefaultTimeout     30.0
#define PINRemoteImageMaxRetries                3
#define PINRemoteImageRetryDelayBase            4

//A limit of 200 characters is chosen because PINDiskCache
//may expand the length by encoding certain characters
#define PINRemoteImageManagerCacheKeyMaxLength 200

PINOperationQueuePriority operationPriorityWithImageManagerPriority(PINRemoteImageManagerPriority priority);
PINOperationQueuePriority operationPriorityWithImageManagerPriority(PINRemoteImageManagerPriority priority) {
    switch (priority) {
        case PINRemoteImageManagerPriorityLow:
            return PINOperationQueuePriorityLow;
            break;
            
        case PINRemoteImageManagerPriorityDefault:
            return PINOperationQueuePriorityDefault;
            break;
            
        case PINRemoteImageManagerPriorityHigh:
            return PINOperationQueuePriorityHigh;
            break;
    }
}

float dataTaskPriorityWithImageManagerPriority(PINRemoteImageManagerPriority priority) {
    switch (priority) {
        case PINRemoteImageManagerPriorityLow:
            return 0.0;
            break;
            
        case PINRemoteImageManagerPriorityDefault:
            return 0.5;
            break;
            
        case PINRemoteImageManagerPriorityHigh:
            return 1.0;
            break;
    }
}

NSString * const PINRemoteImageManagerErrorDomain = @"PINRemoteImageManagerErrorDomain";
NSString * const PINRemoteImageCacheKey = @"cacheKey";
typedef void (^PINRemoteImageManagerDataCompletion)(NSData *data, NSError *error);

@interface PINTaskQOS : NSObject

- (instancetype)initWithBPS:(float)bytesPerSecond endDate:(NSDate *)endDate;

@property (nonatomic, strong) NSDate *endDate;
@property (nonatomic, assign) float bytesPerSecond;

@end

@interface PINRemoteImageManager () <PINURLSessionManagerDelegate>
{
  dispatch_queue_t _callbackQueue;
  PINRemoteLock *_lock;
  PINOperationQueue *_concurrentOperationQueue;
  PINRemoteImageDownloadQueue *_urlSessionTaskQueue;
  
  // Necesarry to have a strong reference to _defaultAlternateRepresentationProvider because _alternateRepProvider is __weak
  PINAlternateRepresentationProvider *_defaultAlternateRepresentationProvider;
  __weak PINAlternateRepresentationProvider *_alternateRepProvider;

}

@property (nonatomic, strong) id<PINRemoteImageCaching> cache;
@property (nonatomic, strong) PINURLSessionManager *sessionManager;
@property (nonatomic, assign) NSTimeInterval timeout;
@property (nonatomic, strong) NSMutableDictionary <NSString *, __kindof PINRemoteImageTask *> *tasks;
@property (nonatomic, strong) NSHashTable <NSUUID *> *canceledTasks;
@property (nonatomic, strong) NSArray <NSNumber *> *progressThresholds;
@property (nonatomic, assign) BOOL shouldBlurProgressive;
@property (nonatomic, assign) CGSize maxProgressiveRenderSize;
@property (nonatomic, assign) NSTimeInterval estimatedRemainingTimeThreshold;
@property (nonatomic, strong) dispatch_queue_t callbackQueue;
@property (nonatomic, strong) PINOperationQueue *concurrentOperationQueue;
@property (nonatomic, strong) PINRemoteImageDownloadQueue *urlSessionTaskQueue;
@property (nonatomic, strong) NSMutableArray <PINTaskQOS *> *taskQOS;
@property (nonatomic, assign) float highQualityBPSThreshold;
@property (nonatomic, assign) float lowQualityBPSThreshold;
@property (nonatomic, assign) BOOL shouldUpgradeLowQualityImages;
@property (nonatomic, copy) PINRemoteImageManagerAuthenticationChallenge authenticationChallengeHandler;
@property (nonatomic, strong) NSMutableDictionary <NSString *, NSString *> *httpHeaderFields;
#if DEBUG
@property (nonatomic, assign) float currentBPS;
@property (nonatomic, assign) BOOL overrideBPS;
@property (nonatomic, assign) NSUInteger totalDownloads;
#endif

@end

#pragma mark PINRemoteImageManager

@implementation PINRemoteImageManager

static PINRemoteImageManager *sharedImageManager = nil;
static dispatch_once_t sharedDispatchToken;

+ (instancetype)sharedImageManager
{
    dispatch_once(&sharedDispatchToken, ^{
        sharedImageManager = [[[self class] alloc] init];
    });
    return sharedImageManager;
}

+ (void)setSharedImageManagerWithConfiguration:(NSURLSessionConfiguration *)configuration
{
    NSAssert(sharedImageManager == nil, @"sharedImageManager singleton is already configured");

    dispatch_once(&sharedDispatchToken, ^{
        sharedImageManager = [[[self class] alloc] initWithSessionConfiguration:configuration];
    });
}

- (instancetype)init
{
    return [self initWithSessionConfiguration:nil];
}

- (instancetype)initWithSessionConfiguration:(NSURLSessionConfiguration *)configuration
{
    return [self initWithSessionConfiguration:configuration alternativeRepresentationProvider:nil];
}

- (instancetype)initWithSessionConfiguration:(NSURLSessionConfiguration *)configuration alternativeRepresentationProvider:(id <PINRemoteImageManagerAlternateRepresentationProvider>)alternateRepProvider
{
    return [self initWithSessionConfiguration:configuration alternativeRepresentationProvider:alternateRepProvider imageCache:nil];
}

- (nonnull instancetype)initWithSessionConfiguration:(nullable NSURLSessionConfiguration *)configuration
                   alternativeRepresentationProvider:(nullable id <PINRemoteImageManagerAlternateRepresentationProvider>)alternateRepProvider
                                          imageCache:(nullable id<PINRemoteImageCaching>)imageCache
{
    if (self = [super init]) {
        
        if (imageCache) {
            self.cache = imageCache;
        } else {
            self.cache = [self defaultImageCache];
        }
        
        if (!configuration) {
            configuration = [NSURLSessionConfiguration ephemeralSessionConfiguration];
        }
        _callbackQueue = dispatch_queue_create("PINRemoteImageManagerCallbackQueue", DISPATCH_QUEUE_CONCURRENT);
        _lock = [[PINRemoteLock alloc] initWithName:@"PINRemoteImageManager"];

        _concurrentOperationQueue = [[PINOperationQueue alloc] initWithMaxConcurrentOperations:[[NSProcessInfo processInfo] activeProcessorCount] * 2];
        _urlSessionTaskQueue = [PINRemoteImageDownloadQueue queueWithMaxConcurrentDownloads:10];
        
        self.sessionManager = [[PINURLSessionManager alloc] initWithSessionConfiguration:configuration];
        self.sessionManager.delegate = self;
        
        self.estimatedRemainingTimeThreshold = 0.1;
        self.timeout = PINRemoteImageManagerDefaultTimeout;
        
        _highQualityBPSThreshold = 500000;
        _lowQualityBPSThreshold = 50000; // approximately edge speeds
        _shouldUpgradeLowQualityImages = NO;
        _shouldBlurProgressive = YES;
        _maxProgressiveRenderSize = CGSizeMake(1024, 1024);
        self.tasks = [[NSMutableDictionary alloc] init];
        self.canceledTasks = [[NSHashTable alloc] initWithOptions:NSHashTableWeakMemory capacity:5];
        self.taskQOS = [[NSMutableArray alloc] initWithCapacity:5];
        
        if (alternateRepProvider == nil) {
            _defaultAlternateRepresentationProvider = [[PINAlternateRepresentationProvider alloc] init];
            alternateRepProvider = _defaultAlternateRepresentationProvider;
        }
        _alternateRepProvider = alternateRepProvider;
        _httpHeaderFields = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (id<PINRemoteImageCaching>)defaultImageCache
{
#if USE_PINCACHE
    NSString * const kPINRemoteImageDiskCacheName = @"PINRemoteImageManagerCache";
    NSString * const kPINRemoteImageDiskCacheVersionKey = @"kPINRemoteImageDiskCacheVersionKey";
    const NSInteger kPINRemoteImageDiskCacheVersion = 1;
    NSUserDefaults *pinDefaults = [[NSUserDefaults alloc] init];
    
    NSString *cacheURLRoot = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    
    if ([pinDefaults integerForKey:kPINRemoteImageDiskCacheVersionKey] != kPINRemoteImageDiskCacheVersion) {
        //remove the old version of the disk cache
        NSURL *diskCacheURL = [PINDiskCache cacheURLWithRootPath:cacheURLRoot prefix:PINDiskCachePrefix name:kPINRemoteImageDiskCacheName];
        [[NSFileManager defaultManager] removeItemAtURL:diskCacheURL error:nil];
        [pinDefaults setInteger:kPINRemoteImageDiskCacheVersion forKey:kPINRemoteImageDiskCacheVersionKey];
    }
  
    return [[PINCache alloc] initWithName:kPINRemoteImageDiskCacheName rootPath:cacheURLRoot serializer:^NSData * _Nonnull(id<NSCoding>  _Nonnull object, NSString * _Nonnull key) {
        return (NSData *)object;
    } deserializer:^id<NSCoding> _Nonnull(NSData * _Nonnull data, NSString * _Nonnull key) {
        return data;
    } fileExtension:nil];
#else
    return [[PINRemoteImageBasicCache alloc] init];
#endif
}

- (void)lockOnMainThread
{
#if !DEBUG
    NSAssert(NO, @"lockOnMainThread should only be called for testing on debug builds!");
#endif
    [_lock lock];
}

- (void)lock
{
    NSAssert([NSThread isMainThread] == NO, @"lock should not be called from the main thread!");
    [_lock lock];
}

- (void)unlock
{
    [_lock unlock];
}

- (void)setValue:(nullable NSString *)value forHTTPHeaderField:(nullable NSString *)header {
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        typeof(self) strongSelf = weakSelf;
        [strongSelf lock];
            strongSelf.httpHeaderFields[[header copy]] = [value copy];
        [strongSelf unlock];
    });
}

- (void)setAuthenticationChallenge:(PINRemoteImageManagerAuthenticationChallenge)challengeBlock {
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        typeof(self) strongSelf = weakSelf;
        [strongSelf lock];
            strongSelf.authenticationChallengeHandler = challengeBlock;
        [strongSelf unlock];
    });
}

- (void)setMaxNumberOfConcurrentOperations:(NSInteger)maxNumberOfConcurrentOperations completion:(dispatch_block_t)completion
{
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        typeof(self) strongSelf = weakSelf;
        [strongSelf lock];
            strongSelf.concurrentOperationQueue.maxConcurrentOperations = maxNumberOfConcurrentOperations;
        [strongSelf unlock];
        if (completion) {
            completion();
        }
    });
}

- (void)setMaxNumberOfConcurrentDownloads:(NSInteger)maxNumberOfConcurrentDownloads completion:(dispatch_block_t)completion
{
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        typeof(self) strongSelf = weakSelf;
        [strongSelf lock];
            strongSelf.urlSessionTaskQueue.maxNumberOfConcurrentDownloads = maxNumberOfConcurrentDownloads;
        [strongSelf unlock];
        if (completion) {
            completion();
        }
    });
}

- (void)setEstimatedRemainingTimeThresholdForProgressiveDownloads:(NSTimeInterval)estimatedRemainingTimeThreshold completion:(dispatch_block_t)completion
{
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        typeof(self) strongSelf = weakSelf;
        [strongSelf lock];
            strongSelf.estimatedRemainingTimeThreshold = estimatedRemainingTimeThreshold;
        [strongSelf unlock];
        if (completion) {
            completion();
        }
    });
}

- (void)setProgressThresholds:(NSArray *)progressThresholds completion:(dispatch_block_t)completion
{
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        typeof(self) strongSelf = weakSelf;
        [strongSelf lock];
            strongSelf.progressThresholds = progressThresholds;
        [strongSelf unlock];
        if (completion) {
            completion();
        }
    });
}

- (void)setProgressiveRendersShouldBlur:(BOOL)shouldBlur completion:(nullable dispatch_block_t)completion
{
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        typeof(self) strongSelf = weakSelf;
        [strongSelf lock];
            strongSelf.shouldBlurProgressive = shouldBlur;
        [strongSelf unlock];
        if (completion) {
            completion();
        }
    });
}

- (void)setProgressiveRendersMaxProgressiveRenderSize:(CGSize)maxProgressiveRenderSize completion:(nullable dispatch_block_t)completion
{
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        typeof(self) strongSelf = weakSelf;
        [strongSelf lock];
            strongSelf.maxProgressiveRenderSize = maxProgressiveRenderSize;
        [strongSelf unlock];
        if (completion) {
            completion();
        }
    });
}

- (void)setHighQualityBPSThreshold:(float)highQualityBPSThreshold completion:(dispatch_block_t)completion
{
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        typeof(self) strongSelf = weakSelf;
        [strongSelf lock];
            strongSelf.highQualityBPSThreshold = highQualityBPSThreshold;
        [strongSelf unlock];
        if (completion) {
            completion();
        }
    });
}

- (void)setLowQualityBPSThreshold:(float)lowQualityBPSThreshold completion:(dispatch_block_t)completion
{
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        typeof(self) strongSelf = weakSelf;
        [strongSelf lock];
            strongSelf.lowQualityBPSThreshold = lowQualityBPSThreshold;
        [strongSelf unlock];
        if (completion) {
            completion();
        }
    });
}

- (void)setShouldUpgradeLowQualityImages:(BOOL)shouldUpgradeLowQualityImages completion:(dispatch_block_t)completion
{
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        typeof(self) strongSelf = weakSelf;
        [strongSelf lock];
            strongSelf.shouldUpgradeLowQualityImages = shouldUpgradeLowQualityImages;
        [strongSelf unlock];
        if (completion) {
            completion();
        }
    });
}

- (NSUUID *)downloadImageWithURL:(NSURL *)url
                      completion:(PINRemoteImageManagerImageCompletion)completion
{
    return [self downloadImageWithURL:url
                              options:PINRemoteImageManagerDownloadOptionsNone
                           completion:completion];
}

- (NSUUID *)downloadImageWithURL:(NSURL *)url
                         options:(PINRemoteImageManagerDownloadOptions)options
                      completion:(PINRemoteImageManagerImageCompletion)completion
{
    return [self downloadImageWithURL:url
                              options:options
                        progressImage:nil
                           completion:completion];
}

- (NSUUID *)downloadImageWithURL:(NSURL *)url
                         options:(PINRemoteImageManagerDownloadOptions)options
                   progressImage:(PINRemoteImageManagerImageCompletion)progressImage
                      completion:(PINRemoteImageManagerImageCompletion)completion
{
    return [self downloadImageWithURL:url
                              options:options
                             priority:PINRemoteImageManagerPriorityDefault
                         processorKey:nil
                            processor:nil
                        progressImage:progressImage
                     progressDownload:nil
                           completion:completion
                            inputUUID:nil];
}

- (NSUUID *)downloadImageWithURL:(NSURL *)url
                         options:(PINRemoteImageManagerDownloadOptions)options
                progressDownload:(PINRemoteImageManagerProgressDownload)progressDownload
                      completion:(PINRemoteImageManagerImageCompletion)completion
{
    return [self downloadImageWithURL:url
                              options:options
                             priority:PINRemoteImageManagerPriorityDefault
                         processorKey:nil
                            processor:nil
                        progressImage:nil
                     progressDownload:progressDownload
                           completion:completion
                            inputUUID:nil];
}

- (NSUUID *)downloadImageWithURL:(NSURL *)url
                         options:(PINRemoteImageManagerDownloadOptions)options
                   progressImage:(PINRemoteImageManagerImageCompletion)progressImage
                progressDownload:(PINRemoteImageManagerProgressDownload)progressDownload
                      completion:(PINRemoteImageManagerImageCompletion)completion
{
    return [self downloadImageWithURL:url
                              options:options
                             priority:PINRemoteImageManagerPriorityDefault
                         processorKey:nil
                            processor:nil
                        progressImage:progressImage
                     progressDownload:progressDownload
                           completion:completion
                            inputUUID:nil];
}

- (NSUUID *)downloadImageWithURL:(NSURL *)url
                         options:(PINRemoteImageManagerDownloadOptions)options
                    processorKey:(NSString *)processorKey
                       processor:(PINRemoteImageManagerImageProcessor)processor
                      completion:(PINRemoteImageManagerImageCompletion)completion
{
    return [self downloadImageWithURL:url
                              options:options
                             priority:PINRemoteImageManagerPriorityDefault
                         processorKey:processorKey
                            processor:processor
                        progressImage:nil
                     progressDownload:nil
                           completion:completion
                            inputUUID:nil];
}

- (NSUUID *)downloadImageWithURL:(NSURL *)url
                         options:(PINRemoteImageManagerDownloadOptions)options
                    processorKey:(NSString *)processorKey
                       processor:(PINRemoteImageManagerImageProcessor)processor
                progressDownload:(PINRemoteImageManagerProgressDownload)progressDownload
                      completion:(PINRemoteImageManagerImageCompletion)completion
{
    return [self downloadImageWithURL:url
                          options:options
                         priority:PINRemoteImageManagerPriorityDefault
                     processorKey:processorKey
                        processor:processor
                    progressImage:nil
                 progressDownload:progressDownload
                       completion:completion
                        inputUUID:nil];
}

- (NSUUID *)downloadImageWithURL:(NSURL *)url
                         options:(PINRemoteImageManagerDownloadOptions)options
                        priority:(PINRemoteImageManagerPriority)priority
                    processorKey:(NSString *)processorKey
                       processor:(PINRemoteImageManagerImageProcessor)processor
                   progressImage:(PINRemoteImageManagerImageCompletion)progressImage
                progressDownload:(PINRemoteImageManagerProgressDownload)progressDownload
                      completion:(PINRemoteImageManagerImageCompletion)completion
                       inputUUID:(NSUUID *)UUID
{
    NSAssert((processor != nil && processorKey.length > 0) || (processor == nil && processorKey == nil), @"processor must not be nil and processorKey length must be greater than zero OR processor must be nil and processorKey must be nil");
    
    Class taskClass;
    if (processor && processorKey.length > 0) {
        taskClass = [PINRemoteImageProcessorTask class];
    } else {
        taskClass = [PINRemoteImageDownloadTask class];
    }
    
    NSString *key = [self cacheKeyForURL:url processorKey:processorKey];

    if (url == nil) {
        [self earlyReturnWithOptions:options url:nil key:key object:nil completion:completion];
        return nil;
    }
    
    NSAssert([url isKindOfClass:[NSURL class]], @"url must be of type NSURL, if it's an NSString, we'll try to correct");
    if ([url isKindOfClass:[NSString class]]) {
        url = [NSURL URLWithString:(NSString *)url];
    }

    if (UUID == nil) {
        UUID = [NSUUID UUID];
    }

    if ((options & PINRemoteImageManagerDownloadOptionsIgnoreCache) == 0) {
        //Check to see if the image is in memory cache and we're on the main thread.
        //If so, special case this to avoid flashing the UI
        id object = [self.cache objectFromMemoryForKey:key];
        if (object) {
            if ([self earlyReturnWithOptions:options url:url key:key object:object completion:completion]) {
                return nil;
            }
        }
    }
    
    if ([url.scheme isEqualToString:@"data"]) {
        NSData *data = [NSData dataWithContentsOfURL:url];
        if (data) {
            if ([self earlyReturnWithOptions:options url:url key:key object:data completion:completion]) {
                return nil;
            }
        }
    }
    
    __weak typeof(self) weakSelf = self;
    [_concurrentOperationQueue addOperation:^
     {
         typeof(self) strongSelf = weakSelf;
         [strongSelf lock];
             //check canceled tasks first
             if ([strongSelf.canceledTasks containsObject:UUID]) {
                 PINLog(@"skipping starting %@ because it was canceled.", UUID);
                 [strongSelf unlock];
                 return;
             }
         
             PINRemoteImageTask *task = [strongSelf.tasks objectForKey:key];
             BOOL taskExisted = NO;
             if (task == nil) {
                 task = [[taskClass alloc] init];
                 PINLog(@"Task does not exist creating with key: %@, URL: %@, UUID: %@, task: %p", key, url, UUID, task);
    #if PINRemoteImageLogging
                 task.key = key;
    #endif
             } else {
                 taskExisted = YES;
                 PINLog(@"Task exists, attaching with key: %@, URL: %@, UUID: %@, task: %@", key, url, UUID, task);
             }
             [task addCallbacksWithCompletionBlock:completion progressImageBlock:progressImage progressDownloadBlock:progressDownload withUUID:UUID];
             [strongSelf.tasks setObject:task forKey:key];
             
             BlockAssert(taskClass == [task class], @"Task class should be the same!");
         [strongSelf unlock];
         
         if (taskExisted == NO) {
             [strongSelf.concurrentOperationQueue addOperation:^
              {
                  typeof(self) strongSelf = weakSelf;
                  [strongSelf objectForKey:key options:options completion:^(BOOL found, BOOL valid, PINImage *image, id alternativeRepresentation) {
                      if (found) {
                          if (valid) {
                              typeof(self) strongSelf = weakSelf;
                              [strongSelf callCompletionsWithKey:key image:image alternativeRepresentation:alternativeRepresentation cached:YES error:nil finalized:YES];
                          } else {
                              //Remove completion and try again
                              typeof(self) strongSelf = weakSelf;
                              [strongSelf lock];
                              PINRemoteImageTask *task = [strongSelf.tasks objectForKey:key];
                              [task removeCallbackWithUUID:UUID];
                              if (task.callbackBlocks.count == 0) {
                                  [strongSelf.tasks removeObjectForKey:key];
                              }
                              [strongSelf unlock];
                              
                              //Skip early check
                              [strongSelf downloadImageWithURL:url
                                                       options:options | PINRemoteImageManagerDownloadOptionsSkipEarlyCheck
                                                      priority:priority
                                                  processorKey:processorKey
                                                     processor:processor
                                                 progressImage:(PINRemoteImageManagerImageCompletion)progressImage
                                              progressDownload:nil
                                                    completion:completion
                                                     inputUUID:UUID];
                          }
                      } else {
                          if ([taskClass isSubclassOfClass:[PINRemoteImageProcessorTask class]]) {
                              //continue processing
                              [strongSelf downloadImageWithURL:url
                                                       options:options
                                                      priority:priority
                                                           key:key
                                                     processor:processor
                                                          UUID:UUID];
                          } else if ([taskClass isSubclassOfClass:[PINRemoteImageDownloadTask class]]) {
                              //continue downloading
                              [strongSelf downloadImageWithURL:url
                                                       options:options
                                                      priority:priority
                                                           key:key
                                                 progressImage:progressImage
                                                          UUID:UUID];
                          }
                      }
                  }];
              } withPriority:operationPriorityWithImageManagerPriority(priority)];
         }
     } withPriority:operationPriorityWithImageManagerPriority(priority)];

    return UUID;
}

- (void)downloadImageWithURL:(NSURL *)url
                     options:(PINRemoteImageManagerDownloadOptions)options
                    priority:(PINRemoteImageManagerPriority)priority
                         key:(NSString *)key
                   processor:(PINRemoteImageManagerImageProcessor)processor
                        UUID:(NSUUID *)UUID
{
    PINRemoteImageProcessorTask *task = nil;
    [self lock];
        task = [self.tasks objectForKey:key];
        //check processing task still exists and download hasn't been started for another task
        if (task == nil || task.downloadTaskUUID != nil) {
            [self unlock];
            return;
        }
        
        __weak typeof(self) weakSelf = self;
        NSUUID *downloadTaskUUID = [self downloadImageWithURL:url
                                                      options:options | PINRemoteImageManagerDownloadOptionsSkipEarlyCheck
                                                   completion:^(PINRemoteImageManagerResult *result)
        {
            typeof(self) strongSelf = weakSelf;
            NSUInteger processCost = 0;
            NSError *error = result.error;
            PINRemoteImageProcessorTask *task = nil;
            [strongSelf lock];
                task = [strongSelf.tasks objectForKey:key];
            [strongSelf unlock];
            //check processing task still exists
            if (task == nil) {
                return;
            }
            if (result.image && error == nil) {
                //If completionBlocks.count == 0, we've canceled before we were even able to start.
                PINImage *image = processor(result, &processCost);
                
                if (image == nil) {
                    error = [NSError errorWithDomain:PINRemoteImageManagerErrorDomain
                                                code:PINRemoteImageManagerErrorFailedToProcessImage
                                            userInfo:nil];
                }
                [strongSelf callCompletionsWithKey:key image:image alternativeRepresentation:nil cached:NO error:error finalized:NO];
                
                if (error == nil && image != nil) {
                    BOOL saveAsJPEG = (options & PINRemoteImageManagerSaveProcessedImageAsJPEG) != 0;
                    NSData *diskData = nil;
                    if (saveAsJPEG) {
                        diskData = PINImageJPEGRepresentation(image, 1.0);
                    } else {
                        diskData = PINImagePNGRepresentation(image);
                    }
                    
                    [strongSelf materializeAndCacheObject:image cacheInDisk:diskData additionalCost:processCost url:url key:key options:options outImage:nil outAltRep:nil];
                }
                
                [strongSelf callCompletionsWithKey:key image:image alternativeRepresentation:nil cached:NO error:error finalized:YES];
            } else {
                if (error == nil) {
                    error = [NSError errorWithDomain:PINRemoteImageManagerErrorDomain
                                                code:PINRemoteImageManagerErrorFailedToFetchImageForProcessing
                                            userInfo:nil];
                }

                [strongSelf callCompletionsWithKey:key image:nil alternativeRepresentation:nil cached:NO error:error finalized:YES];
            }
        }];
        task.downloadTaskUUID = downloadTaskUUID;
    [self unlock];
}

- (void)downloadImageWithURL:(NSURL *)url
                     options:(PINRemoteImageManagerDownloadOptions)options
                    priority:(PINRemoteImageManagerPriority)priority
                         key:(NSString *)key
               progressImage:(PINRemoteImageManagerImageCompletion)progressImage
                        UUID:(NSUUID *)UUID
{
    NSString *resumeKey = [self resumeCacheKeyForURL:url];
    PINResume *resume = [self.cache objectFromMemoryForKey:resumeKey];
    
    [self lock];
        PINRemoteImageDownloadTask *task = [self.tasks objectForKey:key];
        if (task.urlSessionTask == nil && task.callbackBlocks.count > 0 && task.numberOfRetries == 0) {
            //If completionBlocks.count == 0, we've canceled before we were even able to start.
            CFTimeInterval startTime = CACurrentMediaTime();
            task.resume = resume;
            NSURLSessionDataTask *urlSessionTask = [self sessionTaskWithURL:url key:key resumeData:resume options:options priority:priority];
            task.urlSessionTask = urlSessionTask;
            task.sessionTaskStartTime = startTime;
        }
    [self unlock];
}

-(BOOL)insertImageDataIntoCache:(nonnull NSData*)data
                        withURL:(nonnull NSURL *)url
                   processorKey:(nullable NSString *)processorKey
                 additionalCost:(NSUInteger)additionalCost
{
  
  if (url != nil) {
    NSString *key = [self cacheKeyForURL:url processorKey:processorKey];
    
    PINRemoteImageManagerDownloadOptions options = PINRemoteImageManagerDownloadOptionsSkipDecode & PINRemoteImageManagerDownloadOptionsSkipEarlyCheck;
    PINRemoteImageMemoryContainer *container = [[PINRemoteImageMemoryContainer alloc] init];
    container.data = data;
    
    return [self materializeAndCacheObject:container cacheInDisk:data additionalCost:additionalCost url:url key:key options:options outImage: nil outAltRep: nil];
  }
  
  return NO;
}

- (BOOL)earlyReturnWithOptions:(PINRemoteImageManagerDownloadOptions)options url:(NSURL *)url key:(NSString *)key object:(id)object completion:(PINRemoteImageManagerImageCompletion)completion
{
    PINImage *image = nil;
    id alternativeRepresentation = nil;
    PINRemoteImageResultType resultType = PINRemoteImageResultTypeNone;

    BOOL allowEarlyReturn = !(PINRemoteImageManagerDownloadOptionsSkipEarlyCheck & options);

    if (url != nil && object != nil) {
        resultType = PINRemoteImageResultTypeMemoryCache;
        [self materializeAndCacheObject:object url:url key:key options:options outImage:&image outAltRep:&alternativeRepresentation];
    }
    
    if (completion && ((image || alternativeRepresentation) || (url == nil))) {
        //If we're on the main thread, special case to call completion immediately
        NSError *error = nil;
        if (!url) {
            error = [NSError errorWithDomain:NSURLErrorDomain
                                        code:NSURLErrorUnsupportedURL
                                    userInfo:@{ NSLocalizedDescriptionKey : @"unsupported URL" }];
        }
        if (allowEarlyReturn && [NSThread isMainThread]) {
            completion([PINRemoteImageManagerResult imageResultWithImage:image
                                               alternativeRepresentation:alternativeRepresentation
                                                           requestLength:0
                                                                   error:error
                                                              resultType:resultType
                                                                    UUID:nil]);
        } else {
            dispatch_async(self.callbackQueue, ^{
                completion([PINRemoteImageManagerResult imageResultWithImage:image
                                                   alternativeRepresentation:alternativeRepresentation
                                                               requestLength:0
                                                                       error:error
                                                                  resultType:resultType
                                                                        UUID:nil]);
            });
        }
        return YES;
    }
    return NO;
}

- (NSURLSessionDataTask *)sessionTaskWithURL:(NSURL *)url
                                         key:(NSString *)key
                                  resumeData:(PINResume *)resume
                                     options:(PINRemoteImageManagerDownloadOptions)options
                                    priority:(PINRemoteImageManagerPriority)priority
{
    __weak typeof(self) weakSelf = self;
    return [self downloadDataWithURL:url
                                 key:key
                          resumeData:resume
                            priority:priority
                          completion:^(NSData *data, NSError *error)
    {
        [_concurrentOperationQueue addOperation:^
        {
            typeof(self) strongSelf = weakSelf;
            NSError *remoteImageError = error;
            PINImage *image = nil;
            id alternativeRepresentation = nil;
            
            if (remoteImageError && [[self class] retriableError:remoteImageError]) {
                //attempt to retry after delay
                BOOL retry = NO;
                NSUInteger newNumberOfRetries = 0;
                [strongSelf lock];
                    PINRemoteImageDownloadTask *task = [strongSelf.tasks objectForKey:key];
                    if (task.numberOfRetries < PINRemoteImageMaxRetries && (options & PINRemoteImageManagerDownloadOptionsSkipRetry) == NO) {
                        retry = YES;
                        newNumberOfRetries = ++task.numberOfRetries;
                      
                        // Clear out the exsiting progress image or else new data from retry will be appended
                        task.progressImage = nil;
                        task.urlSessionTask = nil;
                    }
                [strongSelf unlock];
                
                if (retry) {
                    int64_t delay = powf(PINRemoteImageRetryDelayBase, newNumberOfRetries);
                    PINLog(@"Retrying download of %@ in %d seconds.", URL, delay);
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                        typeof(self) strongSelf = weakSelf;
                        [strongSelf lock];
                            PINRemoteImageDownloadTask *task = [strongSelf.tasks objectForKey:key];
                            if (task.urlSessionTask == nil && task.callbackBlocks.count > 0) {
                                //If completionBlocks.count == 0, we've canceled before we were even able to start.
                                //If there was an error, do not attempt to use resume data
                                NSURLSessionDataTask *urlSessionTask = [strongSelf sessionTaskWithURL:url key:key resumeData:nil options:options priority:priority];
                                task.urlSessionTask = urlSessionTask;
                            }
                        [strongSelf unlock];
                    });
                    return;
                }
            } else if (remoteImageError == nil) {
                //stores the object in the caches
                [strongSelf materializeAndCacheObject:data cacheInDisk:data additionalCost:0 url:url key:key options:options outImage:&image outAltRep:&alternativeRepresentation];
            }
            
            if (error == nil && image == nil && alternativeRepresentation == nil) {
                remoteImageError = [NSError errorWithDomain:PINRemoteImageManagerErrorDomain
                                                       code:PINRemoteImageManagerErrorFailedToDecodeImage
                                                   userInfo:nil];
            }
            
            [strongSelf callCompletionsWithKey:key image:image alternativeRepresentation:alternativeRepresentation cached:NO error:remoteImageError finalized:YES];
        } withPriority:operationPriorityWithImageManagerPriority(priority)];
    }];
}

+ (BOOL)retriableError:(NSError *)remoteImageError
{
    if ([remoteImageError.domain isEqualToString:PINURLErrorDomain]) {
        return remoteImageError.code >= 500;
    } else if ([remoteImageError.domain isEqualToString:NSURLErrorDomain] && remoteImageError.code == NSURLErrorUnsupportedURL) {
        return NO;
    } else if ([remoteImageError.domain isEqualToString:PINRemoteImageManagerErrorDomain]) {
        return NO;
    }
    return YES;
}

- (NSURLSessionDataTask *)downloadDataWithURL:(NSURL *)url
                                          key:(NSString *)key
                                   resumeData:(PINResume *)resume
                                     priority:(PINRemoteImageManagerPriority)priority
                                   completion:(PINRemoteImageManagerDataCompletion)completion
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url
                                                           cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                                       timeoutInterval:self.timeout];
    
    NSMutableDictionary *headers = [self.httpHeaderFields mutableCopy];
    
    if (resume) {
        headers[@"If-Range"] = resume.ifRange;
        headers[@"Range"] = [NSString stringWithFormat:@"bytes=%tu-", resume.resumeData.length];
    }
    
    if (headers.count > 0) {
        request.allHTTPHeaderFields = headers;
    }
    
    [NSURLProtocol setProperty:key forKey:PINRemoteImageCacheKey inRequest:request];
    
    __weak typeof(self) weakSelf = self;
    NSURLSessionDataTask *dataTask = [self.urlSessionTaskQueue addDownloadWithSessionManager:self.sessionManager
                                                                                     request:request
                                                                                    priority:priority
                                                                           completionHandler:^(NSURLResponse * _Nonnull response, NSError * _Nonnull error)
    {
        typeof(self) strongSelf = weakSelf;
#if DEBUG
        [strongSelf lock];
            strongSelf->_totalDownloads++;
        [strongSelf unlock];
#endif
        
#if PINRemoteImageLogging
        if (error && error.code != NSURLErrorCancelled) {
            PINLog(@"Failed downloading image: %@ with error: %@", url, error);
        } else if (error == nil && response.expectedContentLength == 0) {
            PINLog(@"image is empty at URL: %@", url);
        } else {
            PINLog(@"Finished downloading image: %@", url);
        }
#endif
        
        if (error.code != NSURLErrorCancelled) {
            [strongSelf lock];
                PINRemoteImageDownloadTask *task = [strongSelf.tasks objectForKey:key];
                NSData *data = task.progressImage.data;
            [strongSelf unlock];
            
            if (error == nil && data == nil) {
                error = [NSError errorWithDomain:PINRemoteImageManagerErrorDomain
                                            code:PINRemoteImageManagerErrorImageEmpty
                                        userInfo:nil];
            }
            
            completion(data, error);
        }
    }];
    
    if (PINNSURLSessionTaskSupportsPriority) {
        dataTask.priority = dataTaskPriorityWithImageManagerPriority(priority);
    }
    
    return dataTask;
}

- (void)callCompletionsWithKey:(NSString *)key image:(PINImage *)image alternativeRepresentation:(id)alternativeRepresentation cached:(BOOL)cached error:(NSError *)error finalized:(BOOL)finalized
{
    [self lock];
        PINRemoteImageDownloadTask *task = [self.tasks objectForKey:key];
        [task callCompletionsWithQueue:self.callbackQueue remove:!finalized withImage:image alternativeRepresentation:alternativeRepresentation cached:cached error:error];
        if (finalized) {
            [self.tasks removeObjectForKey:key];
        }
    [self unlock];
}

#pragma mark - Prefetching

- (NSArray<NSUUID *> *)prefetchImagesWithURLs:(NSArray <NSURL *> *)urls
{
    return [self prefetchImagesWithURLs:urls options:PINRemoteImageManagerDownloadOptionsNone | PINRemoteImageManagerDownloadOptionsSkipEarlyCheck];
}

- (NSArray<NSUUID *> *)prefetchImagesWithURLs:(NSArray <NSURL *> *)urls options:(PINRemoteImageManagerDownloadOptions)options
{
    NSMutableArray *tasks = [NSMutableArray arrayWithCapacity:urls.count];
    for (NSURL *url in urls) {
        NSUUID *task = [self prefetchImageWithURL:url options:options];
        if (task != nil) {
            [tasks addObject:task];
        }
    }
    return tasks;
}

- (NSUUID *)prefetchImageWithURL:(NSURL *)url
{
    return [self prefetchImageWithURL:url options:PINRemoteImageManagerDownloadOptionsNone | PINRemoteImageManagerDownloadOptionsSkipEarlyCheck];
}

- (NSUUID *)prefetchImageWithURL:(NSURL *)url options:(PINRemoteImageManagerDownloadOptions)options
{
    return [self downloadImageWithURL:url
                              options:options
                             priority:PINRemoteImageManagerPriorityLow
                         processorKey:nil
                            processor:nil
                        progressImage:nil
                     progressDownload:nil
                           completion:nil
                            inputUUID:nil];
}

#pragma mark - Cancelation & Priority

- (void)cancelTaskWithUUID:(NSUUID *)UUID
{
    [self cancelTaskWithUUID:UUID storeResumeData:NO];
}

- (void)cancelTaskWithUUID:(nonnull NSUUID *)UUID storeResumeData:(BOOL)storeResumeData
{
    if (UUID == nil) {
        return;
    }
    PINLog(@"Attempting to cancel UUID: %@", UUID);
    __weak typeof(self) weakSelf = self;
    [_concurrentOperationQueue addOperation:^{
        typeof(self) strongSelf = weakSelf;
        NSData *resumeData = nil;
        NSURL *resumeURL = nil;
        NSString *ifRange = nil;
        long long totalBytes = 0;
        [strongSelf lock];
            NSString *taskKey = nil;
            PINRemoteImageTask *taskToEvaluate = [strongSelf _locked_taskForUUID:UUID key:&taskKey];
            
            if (taskToEvaluate == nil) {
                //maybe task hasn't been added to task list yet, add it to canceled tasks.
                //there's no need to ever remove a UUID from canceledTasks because it is weak.
                [strongSelf.canceledTasks addObject:UUID];
            }
            
            if ([taskToEvaluate cancelWithUUID:UUID manager:strongSelf]) {
                [strongSelf.tasks removeObjectForKey:taskKey];
                
                if ([taskToEvaluate isKindOfClass:[PINRemoteImageDownloadTask class]]) {
                    PINRemoteImageDownloadTask *downloadTask = (PINRemoteImageDownloadTask *)taskToEvaluate;
                    [strongSelf.urlSessionTaskQueue removeDownloadTaskFromQueue:downloadTask.urlSessionTask];
                    
                    if (storeResumeData && downloadTask.ifRange) {
                        ifRange = downloadTask.ifRange;
                        totalBytes = downloadTask.totalBytes;
                        resumeData = downloadTask.progressImage.data;
                        resumeURL = downloadTask.urlSessionTask.originalRequest.URL;
                    }
                }
            }
        [strongSelf unlock];
        
        if (resumeData.length > 0) {
            //store resume data away
            [strongSelf storeResumeData:[PINResume resumeData:resumeData ifRange:ifRange totalBytes:totalBytes] forURL:resumeURL];
        }
    } withPriority:PINOperationQueuePriorityHigh];
}

- (void)setPriority:(PINRemoteImageManagerPriority)priority ofTaskWithUUID:(NSUUID *)UUID
{
    if (UUID == nil) {
        return;
    }
    PINLog(@"Setting priority of UUID: %@ priority: %lu", UUID, (unsigned long)priority);
    __weak typeof(self) weakSelf = self;
    [_concurrentOperationQueue addOperation:^{
        typeof(self) strongSelf = weakSelf;
        [strongSelf lock];
            PINRemoteImageTask *task = [strongSelf _locked_taskForUUID:UUID key:NULL];
            [task setPriority:priority];
            if ([task isKindOfClass:[PINRemoteImageDownloadTask class]]) {
                PINRemoteImageDownloadTask *downloadTask = (PINRemoteImageDownloadTask *)task;
                if (downloadTask.urlSessionTask) {
                    [strongSelf.urlSessionTaskQueue setQueuePriority:priority forTask:downloadTask.urlSessionTask];
                }
            }
        [strongSelf unlock];
    } withPriority:PINOperationQueuePriorityHigh];
}

- (void)setProgressImageCallback:(nullable PINRemoteImageManagerImageCompletion)progressImageCallback ofTaskWithUUID:(nonnull NSUUID *)UUID
{
    if (UUID == nil) {
        return;
    }
    
    PINLog(@"setting progress block of UUID: %@ progressBlock: %@", UUID, progressImageCallback);
    __weak typeof(self) weakSelf = self;
    [_concurrentOperationQueue addOperation:^{
        typeof(self) strongSelf = weakSelf;
        [strongSelf lock];
            PINRemoteImageTask *task = [strongSelf _locked_taskForUUID:UUID key:NULL];
            if ([task isKindOfClass:[PINRemoteImageDownloadTask class]]) {
                PINRemoteImageCallbacks *callbacks = task.callbackBlocks[UUID];
                callbacks.progressImageBlock = progressImageCallback;
            }
        [strongSelf unlock];
    } withPriority:PINOperationQueuePriorityHigh];
}

#pragma mark - Caching

- (void)imageFromCacheWithCacheKey:(NSString *)cacheKey
                        completion:(PINRemoteImageManagerImageCompletion)completion
{
    [self imageFromCacheWithCacheKey:cacheKey options:PINRemoteImageManagerDownloadOptionsNone completion:completion];
}

- (void)imageFromCacheWithCacheKey:(NSString *)cacheKey
                           options:(PINRemoteImageManagerDownloadOptions)options
                        completion:(PINRemoteImageManagerImageCompletion)completion
{
    [self imageFromCacheWithURL:nil processorKey:nil cacheKey:cacheKey options:options completion:completion];
}

- (void)imageFromCacheWithURL:(nonnull NSURL *)url
                 processorKey:(nullable NSString *)processorKey
                      options:(PINRemoteImageManagerDownloadOptions)options
                   completion:(nonnull PINRemoteImageManagerImageCompletion)completion
{
    [self imageFromCacheWithURL:url processorKey:processorKey cacheKey:nil options:options completion:completion];
}

- (void)imageFromCacheWithURL:(NSURL *)url
                 processorKey:(NSString *)processorKey
                     cacheKey:(NSString *)cacheKey
                      options:(PINRemoteImageManagerDownloadOptions)options
                   completion:(PINRemoteImageManagerImageCompletion)completion
{
    CFTimeInterval requestTime = CACurrentMediaTime();
    
    if ((PINRemoteImageManagerDownloadOptionsSkipEarlyCheck & options) == NO && [NSThread isMainThread]) {
        PINRemoteImageManagerResult *result = [self synchronousImageFromCacheWithURL:url processorKey:processorKey cacheKey:cacheKey options:options];
        if (result.image && result.error) {
            completion((result));
            return;
        }
    }
    
    [self objectForURL:url processorKey:processorKey key:cacheKey options:options completion:^(BOOL found, BOOL valid, PINImage *image, id alternativeRepresentation) {
        NSError *error = nil;
        if (valid == NO) {
            error = [NSError errorWithDomain:PINRemoteImageManagerErrorDomain
                                        code:PINRemoteImageManagerErrorInvalidItemInCache
                                    userInfo:nil];
        }
        
        dispatch_async(self.callbackQueue, ^{
            completion([PINRemoteImageManagerResult imageResultWithImage:image
                                               alternativeRepresentation:alternativeRepresentation
                                                           requestLength:CACurrentMediaTime() - requestTime
                                                                   error:error
                                                              resultType:PINRemoteImageResultTypeCache
                                                                    UUID:nil]);
        });
    }];
}

- (PINRemoteImageManagerResult *)synchronousImageFromCacheWithCacheKey:(NSString *)cacheKey options:(PINRemoteImageManagerDownloadOptions)options
{
    return [self synchronousImageFromCacheWithURL:nil processorKey:nil cacheKey:cacheKey options:options];
}

- (nonnull PINRemoteImageManagerResult *)synchronousImageFromCacheWithURL:(NSURL *)url processorKey:(nullable NSString *)processorKey options:(PINRemoteImageManagerDownloadOptions)options
{
    return [self synchronousImageFromCacheWithURL:url processorKey:processorKey cacheKey:nil options:options];
}

- (PINRemoteImageManagerResult *)synchronousImageFromCacheWithURL:(NSURL *)url processorKey:(NSString *)processorKey cacheKey:(NSString *)cacheKey options:(PINRemoteImageManagerDownloadOptions)options
{
    CFTimeInterval requestTime = CACurrentMediaTime();
  
    if (cacheKey == nil && url == nil) {
        return nil;
    }
  
    cacheKey = cacheKey ?: [self cacheKeyForURL:url processorKey:processorKey];
    
    id object = [self.cache objectFromMemoryForKey:cacheKey];
    PINImage *image;
    id alternativeRepresentation;
    NSError *error = nil;
    if (object == nil) {
        image = nil;
        alternativeRepresentation = nil;
    } else if ([self materializeAndCacheObject:object url:url key:cacheKey options:options outImage:&image outAltRep:&alternativeRepresentation] == NO) {
        error = [NSError errorWithDomain:PINRemoteImageManagerErrorDomain
                                    code:PINRemoteImageManagerErrorInvalidItemInCache
                                userInfo:nil];
    }
    
    return [PINRemoteImageManagerResult imageResultWithImage:image
                                   alternativeRepresentation:alternativeRepresentation
                                               requestLength:CACurrentMediaTime() - requestTime
                                                       error:error
                                                  resultType:PINRemoteImageResultTypeMemoryCache
                                                        UUID:nil];
}

#pragma mark - Session Task Blocks

- (void)didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge forTask:(NSURLSessionTask *)dataTask completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *credential))completionHandler {
    [self lock];
        if (self.authenticationChallengeHandler) {
            self.authenticationChallengeHandler(dataTask, challenge, completionHandler);
        } else {
            completionHandler(NSURLSessionAuthChallengePerformDefaultHandling, nil);
        }
    [self unlock];
}

- (void)didReceiveResponse:(nonnull NSURLResponse *)response forTask:(nonnull NSURLSessionTask *)dataTask
{
    [self lock];
        NSString *cacheKey = [NSURLProtocol propertyForKey:PINRemoteImageCacheKey inRequest:dataTask.originalRequest];
        PINRemoteImageDownloadTask *task = [self.tasks objectForKey:cacheKey];
    [self unlock];
    
    if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        
        // Got partial data back for a resume
        if (httpResponse.statusCode == 206) {
            PINResume *resume = nil;
            PINProgressiveImage *progressImage = nil;
            [self lock];
                NSAssert(task.resume != nil, @"We received a partial response but don't have resume data");
                resume = task.resume;
                [self _locked_setupProgressImageIfNeeded:task];
                progressImage = task.progressImage;
                BOOL hasProgressBlocks = task.hasProgressBlocks;
                BOOL shouldBlur = self.shouldBlurProgressive;
                CGSize maxProgressiveRenderSize = self.maxProgressiveRenderSize;
            
                [task callProgressDownloadWithQueue:self.callbackQueue completedBytes:dataTask.countOfBytesReceived totalBytes:dataTask.countOfBytesExpectedToReceive];
            [self unlock];
            
            [progressImage updateProgressiveImageWithData:resume.resumeData expectedNumberOfBytes:resume.totalBytes isResume:YES];
            
            if (hasProgressBlocks) {
                [self callProgressWithProgressImageIfNecessary:progressImage cacheKey:cacheKey shouldBlur:shouldBlur maxProgressiveRenderSize:maxProgressiveRenderSize];
            }
        } else {
            //Check if there's resume data and we didn't get back a 206, get rid of it
            [self lock];
                task.resume = nil;
            [self unlock];
        }
        
        // Check to see if the server supports resume
        if ([[httpResponse allHeaderFields][@"Accept-Ranges"] isEqualToString:@"bytes"]) {
            NSString *ifRange = nil;
            NSString *etag = nil;

            if ((etag = [httpResponse allHeaderFields][@"ETag"])) {
                if ([etag hasPrefix:@"W/"] == NO) {
                    ifRange = etag;
                }
            } else {
                ifRange = [httpResponse allHeaderFields][@"Last-Modified"];
            }
            
            if (ifRange.length > 0) {
                [self lock];
                    task.ifRange = ifRange;
                    task.totalBytes = httpResponse.expectedContentLength;
                [self unlock];
            }
        }
    }
}

- (void)didReceiveData:(NSData *)data forTask:(NSURLSessionTask *)dataTask
{
    [self lock];
        NSString *cacheKey = [NSURLProtocol propertyForKey:PINRemoteImageCacheKey inRequest:dataTask.originalRequest];
        PINRemoteImageDownloadTask *task = [self.tasks objectForKey:cacheKey];
        [self _locked_setupProgressImageIfNeeded:task];

        PINProgressiveImage *progressiveImage = task.progressImage;
        BOOL hasProgressBlocks = task.hasProgressBlocks;
        BOOL shouldBlur = self.shouldBlurProgressive;
        CGSize maxProgressiveRenderSize = self.maxProgressiveRenderSize;
    
        [task callProgressDownloadWithQueue:self.callbackQueue completedBytes:dataTask.countOfBytesReceived totalBytes:dataTask.countOfBytesExpectedToReceive];
    [self unlock];
    
    [progressiveImage updateProgressiveImageWithData:data expectedNumberOfBytes:[dataTask countOfBytesExpectedToReceive] isResume:NO];
    
    if (hasProgressBlocks) {
        [self callProgressWithProgressImageIfNecessary:progressiveImage cacheKey:cacheKey shouldBlur:shouldBlur maxProgressiveRenderSize:maxProgressiveRenderSize];
    }
}

- (void)callProgressWithProgressImageIfNecessary:(PINProgressiveImage *)progress
                                        cacheKey:(NSString *)cacheKey
                                      shouldBlur:(BOOL)shouldBlur
                        maxProgressiveRenderSize:(CGSize)maxProgressiveRenderSize
{
    if (PINNSOperationSupportsBlur) {
        __weak typeof(self) weakSelf = self;
        [_concurrentOperationQueue addOperation:^{
            typeof(self) strongSelf = weakSelf;
            CGFloat renderedImageQuality = 1.0;
            PINImage *progressImage = [progress currentImageBlurred:shouldBlur maxProgressiveRenderSize:maxProgressiveRenderSize renderedImageQuality:&renderedImageQuality];
            if (progressImage) {
                [strongSelf lock];
                    PINRemoteImageDownloadTask *task = strongSelf.tasks[cacheKey];
                    [task callProgressImageWithQueue:strongSelf.callbackQueue withImage:progressImage renderedImageQuality:renderedImageQuality];
                [strongSelf unlock];
            }
        } withPriority:PINOperationQueuePriorityLow];
    }
}

- (void)didCompleteTask:(NSURLSessionTask *)task withError:(NSError *)error
{
    if (error == nil && [task isKindOfClass:[NSURLSessionDataTask class]]) {
        NSURLSessionDataTask *dataTask = (NSURLSessionDataTask *)task;
        [self lock];
            NSString *cacheKey = [NSURLProtocol propertyForKey:PINRemoteImageCacheKey inRequest:dataTask.originalRequest];
            PINRemoteImageDownloadTask *task = [self.tasks objectForKey:cacheKey];
            task.sessionTaskEndTime = CACurrentMediaTime();
            CFTimeInterval taskLength = task.sessionTaskEndTime - task.sessionTaskStartTime;
        [self unlock];
        
        float bytesPerSecond = dataTask.countOfBytesReceived / taskLength;
        [self addTaskBPS:bytesPerSecond endDate:[NSDate date]];
    }
}

#pragma mark - QOS

- (float)currentBytesPerSecond
{
    [self lock];
    #if DEBUG
        if (self.overrideBPS) {
            float currentBPS = self.currentBPS;
            [self unlock];
            return currentBPS;
        }
    #endif
        
        const NSTimeInterval validThreshold = 60.0;
        __block NSUInteger count = 0;
        __block float bps = 0;
        __block BOOL valid = NO;
        
        NSDate *threshold = [NSDate dateWithTimeIntervalSinceNow:-validThreshold];
        [self.taskQOS enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(PINTaskQOS *taskQOS, NSUInteger idx, BOOL *stop) {
            if ([taskQOS.endDate compare:threshold] == NSOrderedAscending) {
                *stop = YES;
                return;
            }
            valid = YES;
            count++;
            bps += taskQOS.bytesPerSecond;
            
        }];
    [self unlock];
    
    if (valid == NO) {
        return -1;
    }
    
    return bps / (float)count;
}

- (void)addTaskBPS:(float)bytesPerSecond endDate:(NSDate *)endDate
{
    //if bytesPerSecond is less than or equal to zero, ignore.
    if (bytesPerSecond <= 0) {
        return;
    }
    
    [self lock];
        if (self.taskQOS.count >= 5) {
            [self.taskQOS removeObjectAtIndex:0];
        }
        
        PINTaskQOS *taskQOS = [[PINTaskQOS alloc] initWithBPS:bytesPerSecond endDate:endDate];
        
        [self.taskQOS addObject:taskQOS];
        [self.taskQOS sortUsingComparator:^NSComparisonResult(PINTaskQOS *obj1, PINTaskQOS *obj2) {
            return [obj1.endDate compare:obj2.endDate];
        }];
    
    [self unlock];
}

#if DEBUG
- (void)setCurrentBytesPerSecond:(float)currentBPS
{
    [self lockOnMainThread];
        _overrideBPS = YES;
        _currentBPS = currentBPS;
    [self unlock];
}
#endif

- (NSUUID *)downloadImageWithURLs:(NSArray <NSURL *> *)urls
                          options:(PINRemoteImageManagerDownloadOptions)options
                    progressImage:(PINRemoteImageManagerImageCompletion)progressImage
                       completion:(PINRemoteImageManagerImageCompletion)completion
{
    NSUUID *UUID = [NSUUID UUID];
    if (urls.count <= 1) {
        NSURL *url = [urls firstObject];
        [self downloadImageWithURL:url
                           options:options
                          priority:PINRemoteImageManagerPriorityDefault
                      processorKey:nil
                         processor:nil
                     progressImage:progressImage
                  progressDownload:nil
                        completion:completion
                         inputUUID:UUID];
        return UUID;
    }
    
    __weak typeof(self) weakSelf = self;
    [self.concurrentOperationQueue addOperation:^{
        __block NSInteger highestQualityDownloadedIdx = -1;
        typeof(self) strongSelf = weakSelf;
        
        //check for the highest quality image already in cache. It's possible that an image is in the process of being
        //cached when this is being run. In which case two things could happen:
        // -    If network conditions dictate that a lower quality image should be downloaded than the one that is currently
        //      being cached, it will be downloaded in addition. This is not ideal behavior, worst case scenario and unlikely.
        // -    If network conditions dictate that the same quality image should be downloaded as the one being cached, no
        //      new image will be downloaded as either the caching will have finished by the time we actually request it or
        //      the task will still exist and our callback will be attached. In this case, no detrimental behavior will have
        //      occurred.
        [urls enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(NSURL *url, NSUInteger idx, BOOL *stop) {
            typeof(self) strongSelf = weakSelf;
            BlockAssert([url isKindOfClass:[NSURL class]], @"url must be of type URL");
            NSString *cacheKey = [strongSelf cacheKeyForURL:url processorKey:nil];
            
            //we don't actually need the object, just need to know it exists so that we can request it later
            BOOL hasObject = [strongSelf.cache objectExistsForKey:cacheKey];
            
            if (hasObject) {
                highestQualityDownloadedIdx = idx;
                *stop = YES;
            }
        }];
        
        float currentBytesPerSecond = [strongSelf currentBytesPerSecond];
        [strongSelf lock];
            float highQualityQPSThreshold = [strongSelf highQualityBPSThreshold];
            float lowQualityQPSThreshold = [strongSelf lowQualityBPSThreshold];
            BOOL shouldUpgradeLowQualityImages = [strongSelf shouldUpgradeLowQualityImages];
        [strongSelf unlock];
        
        NSUInteger desiredImageURLIdx;
        if (currentBytesPerSecond == -1 || currentBytesPerSecond >= highQualityQPSThreshold) {
            desiredImageURLIdx = urls.count - 1;
        } else if (currentBytesPerSecond <= lowQualityQPSThreshold) {
            desiredImageURLIdx = 0;
        } else if (urls.count == 2) {
            desiredImageURLIdx = roundf((currentBytesPerSecond - lowQualityQPSThreshold) / ((highQualityQPSThreshold - lowQualityQPSThreshold) / (float)(urls.count - 1)));
        } else {
            desiredImageURLIdx = ceilf((currentBytesPerSecond - lowQualityQPSThreshold) / ((highQualityQPSThreshold - lowQualityQPSThreshold) / (float)(urls.count - 2)));
        }
        
        NSUInteger downloadIdx;
        //if the highest quality already downloaded is less than what currentBPS would dictate and shouldUpgrade is
        //set, download the new higher quality image. If no image has been cached, download the image dictated by
        //current bps
        if ((highestQualityDownloadedIdx < desiredImageURLIdx && shouldUpgradeLowQualityImages) || highestQualityDownloadedIdx == -1) {
            downloadIdx = desiredImageURLIdx;
        } else {
            downloadIdx = highestQualityDownloadedIdx;
        }
        
        NSURL *downloadURL = [urls objectAtIndex:downloadIdx];
        
        [strongSelf downloadImageWithURL:downloadURL
                                 options:options
                                priority:PINRemoteImageManagerPriorityDefault
                            processorKey:nil
                               processor:nil
                           progressImage:progressImage
                        progressDownload:nil
                              completion:^(PINRemoteImageManagerResult *result) {
                                  typeof(self) strongSelf = weakSelf;
                                  //clean out any lower quality images from the cache
                                  for (NSInteger idx = downloadIdx - 1; idx >= 0; idx--) {
                                      [[strongSelf cache] removeObjectForKey:[strongSelf cacheKeyForURL:[urls objectAtIndex:idx] processorKey:nil]];
                                  }
                                  
                                  if (completion) {
                                      completion(result);
                                  }
                              }
                               inputUUID:UUID];
    } withPriority:PINOperationQueuePriorityDefault];
    return UUID;
}

#pragma mark - Caching

- (BOOL)materializeAndCacheObject:(id)object
                              url:(NSURL *)url
                              key:(NSString *)key
                          options:(PINRemoteImageManagerDownloadOptions)options
                         outImage:(PINImage **)outImage
                        outAltRep:(id *)outAlternateRepresentation
{
    return [self materializeAndCacheObject:object cacheInDisk:nil additionalCost:0 url:url key:key options:options outImage:outImage outAltRep:outAlternateRepresentation];
}

//takes the object from the cache and returns an image or animated image.
//if it's a non-alternative representation and skipDecode is not set it also decompresses the image.
- (BOOL)materializeAndCacheObject:(id)object
                      cacheInDisk:(NSData *)diskData
                   additionalCost:(NSUInteger)additionalCost
                              url:(NSURL *)url
                              key:(NSString *)key
                          options:(PINRemoteImageManagerDownloadOptions)options
                         outImage:(PINImage **)outImage
                        outAltRep:(id *)outAlternateRepresentation
{
    NSAssert(object != nil, @"Object should not be nil.");
    if (object == nil) {
        return NO;
    }
    BOOL alternateRepresentationsAllowed = (PINRemoteImageManagerDisallowAlternateRepresentations & options) == 0;
    BOOL skipDecode = (options & PINRemoteImageManagerDownloadOptionsSkipDecode) != 0;
    __block id alternateRepresentation = nil;
    __block PINImage *image = nil;
    __block NSData *data = nil;
    __block BOOL updateMemoryCache = NO;
    
    PINRemoteImageMemoryContainer *container = nil;
    if ([object isKindOfClass:[PINRemoteImageMemoryContainer class]]) {
        container = (PINRemoteImageMemoryContainer *)object;
        [container.lock lockWithBlock:^{
            data = container.data;
        }];
    } else {
        updateMemoryCache = YES;
        
        // don't need to lock the container here because we just init it.
        container = [[PINRemoteImageMemoryContainer alloc] init];
        
        if ([object isKindOfClass:[PINImage class]]) {
            data = diskData;
            container.image = (PINImage *)object;
        } else if ([object isKindOfClass:[NSData class]]) {
            data = (NSData *)object;
        } else {
            //invalid item in cache
            updateMemoryCache = NO;
            data = nil;
            container = nil;
        }
        
        container.data = data;
    }
    
    if (alternateRepresentationsAllowed) {
        alternateRepresentation = [_alternateRepProvider alternateRepresentationWithData:data options:options];
    }
    
    if (alternateRepresentation == nil) {
        //we need the image
        [container.lock lockWithBlock:^{
            image = container.image;
        }];
        if (image == nil && container.data) {
            image = [PINImage pin_decodedImageWithData:container.data skipDecodeIfPossible:skipDecode];
            
            if (url != nil) {
                image = [PINImage pin_scaledImageForImage:image withKey:key];
            }
            
            if (skipDecode == NO) {
                [container.lock lockWithBlock:^{
                    updateMemoryCache = YES;
                    container.image = image;
                }];
            }
        }
    }
    
    if (updateMemoryCache) {
        [container.lock lockWithBlock:^{
            NSUInteger cacheCost = additionalCost;
            cacheCost += [container.data length];
            CGImageRef imageRef = container.image.CGImage;
            NSAssert(container.image == nil || imageRef != NULL, @"We only cache a decompressed image if we decompressed it ourselves. In that case, it should be backed by a CGImageRef.");
            if (imageRef) {
                cacheCost += CGImageGetHeight(imageRef) * CGImageGetBytesPerRow(imageRef);
            }
            [self.cache setObjectInMemory:container forKey:key withCost:cacheCost];
        }];
    }
    
    if (diskData) {
        [self.cache setObjectOnDisk:diskData forKey:key];
    }
    
    if (outImage) {
        *outImage = image;
    }
    
    if (outAlternateRepresentation) {
        *outAlternateRepresentation = alternateRepresentation;
    }
    
    if (image == nil && alternateRepresentation == nil) {
        PINLog(@"Invalid item in cache");
        [self.cache removeObjectForKey:key completion:nil];
        return NO;
    }
    return YES;
}

- (NSString *)cacheKeyForURL:(NSURL *)url processorKey:(NSString *)processorKey
{
    return [self cacheKeyForURL:url processorKey:processorKey resume:NO];
}

- (NSString *)cacheKeyForURL:(NSURL *)url processorKey:(NSString *)processorKey resume:(BOOL)resume
{
    NSString *cacheKey = [url absoluteString];
    NSAssert((processorKey.length == 0 && resume == YES) || resume == NO, @"It doesn't make sense to use resume with processing.");
    if (processorKey.length > 0) {
        cacheKey = [cacheKey stringByAppendingFormat:@"-<%@>", processorKey];
    }
    if (resume) {
        cacheKey = [@"R-" stringByAppendingString:cacheKey];
    }

    //PINDiskCache uses this key as the filename of the file written to disk
    //Due to the current filesystem used in Darwin, this name must be limited to 255 chars.
    //In case the generated key exceeds PINRemoteImageManagerCacheKeyMaxLength characters,
    //we return the hash of it instead.
    if (cacheKey.length > PINRemoteImageManagerCacheKeyMaxLength) {
        __block CC_MD5_CTX ctx;
        CC_MD5_Init(&ctx);
        NSData *data = [cacheKey dataUsingEncoding:NSUTF8StringEncoding];
        [data enumerateByteRangesUsingBlock:^(const void * _Nonnull bytes, NSRange byteRange, BOOL * _Nonnull stop) {
            CC_MD5_Update(&ctx, bytes, (CC_LONG)byteRange.length);
        }];

        unsigned char digest[CC_MD5_DIGEST_LENGTH];
        CC_MD5_Final(digest, &ctx);

        NSMutableString *hexString  = [NSMutableString stringWithCapacity:(CC_MD5_DIGEST_LENGTH * 2)];
        for (int i = 0; i < CC_MD5_DIGEST_LENGTH; i++) {
            [hexString appendFormat:@"%02lx", (unsigned long)digest[i]];
        }
        cacheKey = [hexString copy];
    }

    return cacheKey;
}

- (void)objectForKey:(NSString *)key options:(PINRemoteImageManagerDownloadOptions)options completion:(void (^)(BOOL found, BOOL valid, PINImage *image, id alternativeRepresentation))completion
{
    return [self objectForURL:nil processorKey:nil key:key options:options completion:completion];
}

- (void)objectForURL:(NSURL *)url processorKey:(NSString *)processorKey key:(NSString *)key options:(PINRemoteImageManagerDownloadOptions)options completion:(void (^)(BOOL found, BOOL valid, PINImage *image, id alternativeRepresentation))completion
{
    if ((options & PINRemoteImageManagerDownloadOptionsIgnoreCache) != 0) {
        completion(NO, YES, nil, nil);
        return;
    }
  
    if (key == nil && url == nil) {
        completion(NO, YES, nil, nil);
        return;
    }
  
    key = key ?: [self cacheKeyForURL:url processorKey:processorKey];

    void (^materialize)(id object) = ^(id object) {
        PINImage *image = nil;
        id alternativeRepresentation = nil;
        BOOL valid = [self materializeAndCacheObject:object
                                                 url:nil
                                                 key:key
                                             options:options
                                            outImage:&image
                                           outAltRep:&alternativeRepresentation];
        
        completion(YES, valid, image, alternativeRepresentation);
    };
    
    PINRemoteImageMemoryContainer *container = [self.cache objectFromMemoryForKey:key];
    if (container) {
        materialize(container);
    } else {
        [self.cache objectFromDiskForKey:key completion:^(id<PINRemoteImageCaching> _Nonnull cache,
                                                         NSString *_Nonnull key,
                                                         id _Nullable object) {
          if (object) {
              materialize(object);
          } else {
              completion(NO, YES, nil, nil);
          }
        }];
    }
}

#pragma mark - Resume support

- (NSString *)resumeCacheKeyForURL:(NSURL *)url
{
    return [self cacheKeyForURL:url processorKey:nil resume:YES];
}

- (void)storeResumeData:(PINResume *)resume forURL:(NSURL *)URL
{
    NSString *resumeKey = [self resumeCacheKeyForURL:URL];
    [self.cache setObjectInMemory:resume forKey:resumeKey withCost:resume.resumeData.length];
}

/// Attempt to find the task with the callbacks for the given uuid
- (nullable PINRemoteImageTask *)_locked_taskForUUID:(NSUUID *)uuid key:(NSString * _Nullable * _Nullable)outKey
{
    __block PINRemoteImageTask *result = nil;

    [self.tasks enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, __kindof PINRemoteImageTask * _Nonnull task, BOOL * _Nonnull stop) {
        // If this isn't our task, just return.
        if (task.callbackBlocks[uuid] == nil) {
            return;
        }

        // Found it! Save our results and end enumeration
        result = task;
        if (outKey != NULL) {
            *outKey = key;
        }
        *stop = YES;
    }];
    return result;
}

- (void)_locked_setupProgressImageIfNeeded:(PINRemoteImageDownloadTask *)task
{
    if (task.progressImage == nil) {
        task.progressImage = [[PINProgressiveImage alloc] init];
        task.progressImage.startTime = task.sessionTaskStartTime;
        task.progressImage.estimatedRemainingTimeThreshold = self.estimatedRemainingTimeThreshold;
        if (self.progressThresholds) {
            task.progressImage.progressThresholds = self.progressThresholds;
        }
    }
}

#if DEBUG
- (NSUInteger)totalDownloads
{
    //hack to avoid main thread assertion since these are only used in testing
    [_lock lock];
        NSUInteger totalDownloads = _totalDownloads;
    [_lock unlock];
    return totalDownloads;
}
#endif

@end

@implementation PINTaskQOS

- (instancetype)initWithBPS:(float)bytesPerSecond endDate:(NSDate *)endDate
{
    if (self = [super init]) {
        self.endDate = endDate;
        self.bytesPerSecond = bytesPerSecond;
    }
    return self;
}

@end
