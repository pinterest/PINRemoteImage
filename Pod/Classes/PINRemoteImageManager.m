//
//  PINRemoteImageManager.m
//  Pods
//
//  Created by Garrett Moon on 8/17/14.
//
//

#import "PINRemoteImageManager.h"

#if USE_FLANIMATED_IMAGE
#import <FLAnimatedImage/FLAnimatedImage.h>
#endif
#import <PINCache/PINCache.h>

#import "PINRemoteImage.h"
#import "PINProgressiveImage.h"
#import "PINRemoteImageCallbacks.h"
#import "PINRemoteImageTask.h"
#import "PINRemoteImageProcessorTask.h"
#import "PINRemoteImageDownloadTask.h"
#import "PINDataTaskOperation.h"
#import "PINURLSessionManager.h"

#import "NSData+ImageDetectors.h"
#import "UIImage+DecodedImage.h"

#define PINRemoteImageManagerDefaultTimeout  60.0

NSOperationQueuePriority operationPriorityWithImageManagerPriority(PINRemoteImageManagerPriority priority) {
    switch (priority) {
        case PINRemoteImageManagerPriorityVeryLow:
            return NSOperationQueuePriorityVeryLow;
            break;
            
        case PINRemoteImageManagerPriorityLow:
            return NSOperationQueuePriorityLow;
            break;
            
        case PINRemoteImageManagerPriorityMedium:
            return NSOperationQueuePriorityNormal;
            break;
            
        case PINRemoteImageManagerPriorityHigh:
            return NSOperationQueuePriorityHigh;
            break;
            
        case PINRemoteImageManagerPriorityVeryHigh:
            return NSOperationQueuePriorityVeryHigh;
            break;
    }
}

float dataTaskPriorityWithImageManagerPriority(PINRemoteImageManagerPriority priority) {
    switch (priority) {
        case PINRemoteImageManagerPriorityVeryLow:
            return 0.0;
            break;
            
        case PINRemoteImageManagerPriorityLow:
            return 0.25;
            break;
            
        case PINRemoteImageManagerPriorityMedium:
            return 0.5;
            break;
            
        case PINRemoteImageManagerPriorityHigh:
            return 0.75;
            break;
            
        case PINRemoteImageManagerPriorityVeryHigh:
            return 1.0;
            break;
    }
}

NSString * const PINRemoteImageManagerErrorDomain = @"PINRemoteImageManagerErrorDomain";
typedef void (^PINRemoteImageManagerDataCompletion)(NSData *data, NSError *error);

@interface NSOperationQueue (PINRemoteImageManager)

- (void)pin_addOperationWithQueuePriority:(PINRemoteImageManagerPriority)priority block:(void (^)(void))block;

@end

@interface PINTaskQOS : NSObject

- (instancetype)initWithBPS:(float)bytesPerSecond endDate:(NSDate *)endDate;

@property (nonatomic, strong) NSDate *endDate;
@property (nonatomic, assign) float bytesPerSecond;

@end

@interface PINRemoteImageManager () <PINURLSessionManagerDelegate>
{
    dispatch_queue_t _callbackQueue;
    NSLock *_lock;
    NSOperationQueue *_concurrentOperationQueue;
    NSOperationQueue *_urlSessionTaskQueue;
}

@property (nonatomic, strong) PINCache *cache;
@property (nonatomic, strong) PINURLSessionManager *sessionManager;
@property (nonatomic, assign) NSTimeInterval timeout;
@property (nonatomic, strong) NSMutableDictionary *tasks;
@property (nonatomic, strong) NSMutableSet *canceledTasks;
@property (nonatomic, strong) NSArray *progressThresholds;
@property (nonatomic, assign) NSTimeInterval estimatedRemainingTimeThreshold;
@property (nonatomic, strong) dispatch_queue_t callbackQueue;
@property (nonatomic, strong) NSOperationQueue *concurrentOperationQueue;
@property (nonatomic, strong) NSOperationQueue *urlSessionTaskQueue;
@property (nonatomic, strong) NSMutableArray *taskQOS;
@property (nonatomic, assign) float highQualityBPSThreshold;
@property (nonatomic, assign) float lowQualityBPSThreshold;
@property (nonatomic, assign) BOOL shouldUpgradeLowQualityImages;
@property (nonatomic, copy) PINRemoteImageManagerAuthenticationChallenge authenticationChallengeHandler;
#if DEBUG
@property (nonatomic, assign) float currentBPS;
@property (nonatomic, assign) BOOL overrideBPS;
@property (nonatomic, assign) NSUInteger totalDownloads;
#endif

@end

#pragma mark PINRemoteImageManager

@implementation PINRemoteImageManager

+ (instancetype)sharedImageManager
{
    static PINRemoteImageManager *sharedImageManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedImageManager = [[[self class] alloc] init];
    });
    return sharedImageManager;
}

- (instancetype)init
{
    return [self initWithSessionConfiguration:nil];
}

- (instancetype)initWithSessionConfiguration:(NSURLSessionConfiguration *)configuration
{
    if (self = [super init]) {
        self.cache = [self defaultImageCache];
        if (!configuration) {
            configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
        }
        _callbackQueue = dispatch_queue_create("PINRemoteImageManagerCallbackQueue", DISPATCH_QUEUE_CONCURRENT);
        _lock = [[NSLock alloc] init];
        _lock.name = @"PINRemoteImageManager";
        _concurrentOperationQueue = [[NSOperationQueue alloc] init];
        _concurrentOperationQueue.name = @"PINRemoteImageManager Concurrent Operation Queue";
        _concurrentOperationQueue.maxConcurrentOperationCount = NSOperationQueueDefaultMaxConcurrentOperationCount;
        if ([[self class] isiOS8OrGreater]) {
            _concurrentOperationQueue.qualityOfService = NSQualityOfServiceBackground;
        }
        _urlSessionTaskQueue = [[NSOperationQueue alloc] init];
        _urlSessionTaskQueue.name = @"PINRemoteImageManager Concurrent URL Session Task Queue";
        _urlSessionTaskQueue.maxConcurrentOperationCount = 10;
        
        self.sessionManager = [[PINURLSessionManager alloc] initWithSessionConfiguration:configuration];
        self.sessionManager.delegate = self;
        
        self.estimatedRemainingTimeThreshold = 0.0;
        self.timeout = PINRemoteImageManagerDefaultTimeout;
        
        _highQualityBPSThreshold = 500000;
        _lowQualityBPSThreshold = 50000; // approximately edge speeds
        _shouldUpgradeLowQualityImages = NO;
        self.tasks = [[NSMutableDictionary alloc] init];
        self.canceledTasks = [[NSMutableSet alloc] init];
        self.taskQOS = [[NSMutableArray alloc] initWithCapacity:5];
    }
    return self;
}

- (PINCache *)defaultImageCache;
{
    return [[PINCache alloc] initWithName:@"PINRemoteImageManagerCache"];
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

- (void)setAuthenticationChallenge:(PINRemoteImageManagerAuthenticationChallenge)aChallenge {
	__weak typeof(self) weakSelf = self;
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		typeof(self) strongSelf = weakSelf;
		[strongSelf lock];
		strongSelf.authenticationChallengeHandler = aChallenge;
		[strongSelf unlock];
	});
}

- (void)setMaxNumberOfConcurrentOperations:(NSInteger)maxNumberOfConcurrentOperations completion:(dispatch_block_t)completion
{
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        typeof(self) strongSelf = weakSelf;
        [strongSelf lock];
            strongSelf.concurrentOperationQueue.maxConcurrentOperationCount = maxNumberOfConcurrentOperations;
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
            strongSelf.urlSessionTaskQueue.maxConcurrentOperationCount = maxNumberOfConcurrentDownloads;
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
                             progress:nil
                           completion:completion];
}

- (NSUUID *)downloadImageWithURL:(NSURL *)url
                         options:(PINRemoteImageManagerDownloadOptions)options
                        progress:(PINRemoteImageManagerImageCompletion)progress
                      completion:(PINRemoteImageManagerImageCompletion)completion
{
    return [self downloadImageWithURL:url
                              options:options
                             priority:PINRemoteImageManagerPriorityMedium
                         processorKey:nil
                            processor:nil
                             progress:progress
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
                             priority:PINRemoteImageManagerPriorityMedium
                         processorKey:processorKey
                            processor:processor
                             progress:nil
                           completion:completion
                            inputUUID:nil];
}

- (NSUUID *)downloadImageWithURL:(NSURL *)url
                         options:(PINRemoteImageManagerDownloadOptions)options
                        priority:(PINRemoteImageManagerPriority)priority
                    processorKey:(NSString *)processorKey
                       processor:(PINRemoteImageManagerImageProcessor)processor
                        progress:(PINRemoteImageManagerImageCompletion)progress
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

    if (url == nil) {
        [self earlyReturnWithOptions:options url:nil object:nil completion:completion];
        return nil;
    }
    
    NSAssert([url isKindOfClass:[NSURL class]], @"url must be of type NSURL, if it's an NSString, we'll try to correct");
    if ([url isKindOfClass:[NSString class]]) {
        url = [NSURL URLWithString:(NSString *)url];
    }

    if (UUID == nil) {
        UUID = [NSUUID UUID];
    }

    NSString *key = [self cacheKeyForURL:url processorKey:processorKey];
    //Check to see if the image is in memory cache and we're on the main thread.
    //If so, special case this to avoid flashing the UI
    id object = [self.cache.memoryCache objectForKey:key];
    if (object) {
        if ([self earlyReturnWithOptions:options url:url object:object completion:completion]) {
            return nil;
        }
    }
    
    __weak typeof(self) weakSelf = self;
    [_concurrentOperationQueue pin_addOperationWithQueuePriority:priority block:^
     {
         typeof(self) strongSelf = weakSelf;
         [strongSelf lock];
             //check canceled tasks first
             if ([strongSelf.canceledTasks containsObject:UUID]) {
                 [strongSelf unlock];
                 return;
             }
             [strongSelf.canceledTasks removeAllObjects];
         
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
             [task addCallbacksWithCompletionBlock:completion progressBlock:progress withUUID:UUID];
             [strongSelf.tasks setObject:task forKey:key];
             
             BlockAssert(taskClass == [task class], @"Task class should be the same!");
         [strongSelf unlock];
         
         if (taskExisted == NO) {
             [strongSelf.concurrentOperationQueue pin_addOperationWithQueuePriority:priority block:^
              {
                  typeof(self) strongSelf = weakSelf;
                  [strongSelf.cache objectForKey:key block:^(PINCache *cache, NSString *key, id object)
                   {
                       typeof(self) strongSelf = weakSelf;
                       [strongSelf.concurrentOperationQueue pin_addOperationWithQueuePriority:priority block:^
                        {
                            typeof(self) strongSelf = weakSelf;
                            if (object) {
                                UIImage *image = nil;
                                FLAnimatedImage *animatedImage = nil;
                                BOOL valid = [strongSelf handleCacheObject:cache
                                                                    object:object
                                                                      uuid:UUID
                                                                       key:key
                                                                   options:options
                                                                  priority:(PINRemoteImageManagerPriority)priority
                                                                  outImage:&image
                                                          outAnimatedImage:&animatedImage];
                                
                                if (valid) {
                                    typeof(self) strongSelf = weakSelf;
                                    [strongSelf lock];
                                        PINRemoteImageTask *task = [strongSelf.tasks objectForKey:key];
                                        [task callCompletionsWithQueue:strongSelf.callbackQueue remove:NO withImage:image animatedImage:animatedImage cached:YES error:nil];
                                        [strongSelf.tasks removeObjectForKey:key];
                                    [strongSelf unlock];
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
                                                            progress:(PINRemoteImageManagerImageCompletion)progress
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
                                                            progress:progress
                                                                UUID:UUID];
                                }
                            }
                        }];
                   }];
              }];
         }
     }];

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
                UIImage *image = processor(result, &processCost);
                
                if (image == nil) {
                    error = [NSError errorWithDomain:PINRemoteImageManagerErrorDomain
                                                code:PINRemoteImageManagerErrorFailedToProcessImage
                                            userInfo:nil];
                }
                [strongSelf lock];
                    //call any completion blocks that are already set
                    PINRemoteImageProcessorTask *task = [strongSelf.tasks objectForKey:key];
                    [task callCompletionsWithQueue:strongSelf.callbackQueue remove:YES withImage:image animatedImage:nil cached:NO error:error];
                [strongSelf unlock];
                
                if (error == nil) {
                    NSUInteger cacheCost = ([image size].width * [image size].height) + processCost;
                    [strongSelf.cache.memoryCache setObject:image
                                                     forKey:key
                                                   withCost:cacheCost
                                                      block:^(PINMemoryCache *cache, NSString *key, id object)
                     {
                         typeof(self) strongSelf = weakSelf;
                         
                         BOOL saveAsJPEG = (options & PINRemoteImageManagerSaveProcessedImageAsJPEG) != 0;
                         NSData *diskData = nil;
                         if (saveAsJPEG) {
                             diskData = UIImageJPEGRepresentation(image, 1.0);
                         } else {
                             diskData = UIImagePNGRepresentation(image);
                         }
                         
                         [strongSelf.cache.diskCache setObject:diskData
                                                        forKey:key
                                                         block:^(PINDiskCache *cache, NSString *key, id<NSCoding> object, NSURL *fileURL)
                          {
                              typeof(self) strongSelf = weakSelf;
                              [strongSelf lock];
                                  //call any completion blocks that were added while we were caching
                                  //and remove session task
                                  PINRemoteImageProcessorTask *task = [strongSelf.tasks objectForKey:key];
                                  [task callCompletionsWithQueue:strongSelf.callbackQueue remove:NO withImage:image animatedImage:nil cached:NO error:nil];
                                  [strongSelf.tasks removeObjectForKey:key];
                              [strongSelf unlock];
                          }];
                     }];
                }
            } else {
                if (error == nil) {
                    error = [NSError errorWithDomain:PINRemoteImageManagerErrorDomain
                                                code:PINRemoteImageManagerErrorFailedToFetchImageForProcessing
                                            userInfo:nil];
                }
                [strongSelf lock];
                    //call any completion blocks that are already set
                    PINRemoteImageProcessorTask *task = [strongSelf.tasks objectForKey:key];
                    [task callCompletionsWithQueue:strongSelf.callbackQueue remove:NO withImage:nil animatedImage:nil cached:NO error:error];
                    [strongSelf.tasks removeObjectForKey:key];
                [strongSelf unlock];
            }
        }];
        task.downloadTaskUUID = downloadTaskUUID;
    [self unlock];
}

- (void)downloadImageWithURL:(NSURL *)url
                     options:(PINRemoteImageManagerDownloadOptions)options
                    priority:(PINRemoteImageManagerPriority)priority
                         key:(NSString *)key
                    progress:(PINRemoteImageManagerImageCompletion)progress
                        UUID:(NSUUID *)UUID
{
    [self lock];
        PINRemoteImageDownloadTask *task = [self.tasks objectForKey:key];
        if (task.urlSessionTaskOperation == nil && task.callbackBlocks.count > 0) {
            //If completionBlocks.count == 0, we've canceled before we were even able to start.
            CFTimeInterval startTime = CACurrentMediaTime();
            PINDataTaskOperation *urlSessionTaskOperation = [self sessionTaskWithURL:url key:key options:options priority:priority];
            task.urlSessionTaskOperation = urlSessionTaskOperation;
            task.sessionTaskStartTime = startTime;
        }
    [self unlock];
}

- (BOOL)earlyReturnWithOptions:(PINRemoteImageManagerDownloadOptions)options url:(NSURL *)url object:(id)object completion:(PINRemoteImageManagerImageCompletion)completion
{
    UIImage *image = nil;
    FLAnimatedImage *animatedImage = nil;
    PINRemoteImageResultType resultType = PINRemoteImageResultTypeNone;

    BOOL allowEarlyReturn = !(PINRemoteImageManagerDownloadOptionsSkipEarlyCheck & options);
    BOOL allowAnimated = !(PINRemoteImageManagerDownloadOptionsIgnoreGIFs & options);

    if (url != nil) {
        resultType = PINRemoteImageResultTypeMemoryCache;
        if ([object isKindOfClass:[UIImage class]]) {
            image = (UIImage *)object;
        } else if (allowAnimated && [object isKindOfClass:[NSData class]] && [(NSData *)object pin_isGIF]) {
#if USE_FLANIMATED_IMAGE
            animatedImage = [FLAnimatedImage animatedImageWithGIFData:object];
#endif
        }
    }
    
    if (completion && ((image || animatedImage) || (url == nil))) {
        //If we're on the main thread, special case to call completion immediately
        NSError *error = nil;
        if (!url) {
            error = [NSError errorWithDomain:NSURLErrorDomain
                                        code:NSURLErrorUnsupportedURL
                                    userInfo:@{ NSLocalizedDescriptionKey : @"unsupported URL" }];
        }
        if (allowEarlyReturn && [NSThread isMainThread]) {
            completion([PINRemoteImageManagerResult imageResultWithImage:image
                                                          animatedImage:animatedImage
                                                          requestLength:0
                                                                  error:error
                                                             resultType:resultType
                                                                   UUID:nil]);
        } else {
            dispatch_async(self.callbackQueue, ^{
                completion([PINRemoteImageManagerResult imageResultWithImage:image
                                                              animatedImage:animatedImage
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

//takes the object from the cache and returns an image or animated image.
//if it's a non-gif and skipDecode is not set it also decompresses the image.
- (BOOL)handleCacheObject:(PINCache *)cache
                   object:(id)object
                     uuid:(NSUUID *)UUID
                      key:(NSString *)key
                  options:(PINRemoteImageManagerDownloadOptions)options
                 priority:(PINRemoteImageManagerPriority)priority
                 outImage:(UIImage **)outImage
         outAnimatedImage:(FLAnimatedImage **)outAnimatedImage
{
    BOOL ignoreGIF = (PINRemoteImageManagerDownloadOptionsIgnoreGIFs & options) != 0;
    FLAnimatedImage *animatedImage = nil;
    UIImage *image = nil;
    if ([object isKindOfClass:[UIImage class]]) {
        image = (UIImage *)object;
    } else if ([object isKindOfClass:[NSData class]]) {
        NSData *imageData = (NSData *)object;
        if ([imageData pin_isGIF] && ignoreGIF == NO) {
#if USE_FLANIMATED_IMAGE
            animatedImage = [[FLAnimatedImage alloc] initWithAnimatedGIFData:imageData];
#endif
        } else {
            BOOL skipDecode = (options & PINRemoteImageManagerDownloadOptionsSkipDecode) != 0;
            image = [UIImage pin_decodedImageWithData:imageData skipDecodeIfPossible:skipDecode];
            //put in memory cache
            if (skipDecode == NO) {
                NSUInteger cacheCost = [image size].width * [image size].height;
                [cache.memoryCache setObject:image
                                      forKey:key
                                    withCost:cacheCost
                                       block:NULL];
            }
        }
    }
    
    if (outImage) {
        *outImage = image;
    }
    
    if (outAnimatedImage) {
        *outAnimatedImage = animatedImage;
    }
    
    if (image == nil && animatedImage == nil) {
        PINLog(@"Invalid item in cache");
        [cache removeObjectForKey:key];
        return NO;
    }
    return YES;
}

- (PINDataTaskOperation *)sessionTaskWithURL:(NSURL *)URL
                                        key:(NSString *)key
                                    options:(PINRemoteImageManagerDownloadOptions)options
                                   priority:(PINRemoteImageManagerPriority)priority
{
    BOOL ignoreGIF = (PINRemoteImageManagerDownloadOptionsIgnoreGIFs & options) != 0;
    __weak typeof(self) weakSelf = self;
    return [self downloadDataWithURL:URL
                                 key:key
                            priority:priority
                          completion:^(NSData *data, NSError *error)
    {
        [_concurrentOperationQueue pin_addOperationWithQueuePriority:priority block:^
        {
            typeof(self) strongSelf = weakSelf;
            NSError *remoteImageError = error;
            NSUInteger cacheCost = 0;
            FLAnimatedImage *animatedImage = nil;
            UIImage *image = nil;
            BOOL skipDecode = (options & PINRemoteImageManagerDownloadOptionsSkipDecode) != 0;
            
            if (remoteImageError == nil) {
                if ([data pin_isGIF] && ignoreGIF == NO) {
#if USE_FLANIMATED_IMAGE
                    animatedImage = [[FLAnimatedImage alloc] initWithAnimatedGIFData:data];
#endif
                    //FLAnimatedImage handles its own caching of frames
                    cacheCost = [data length];
                } else {
                    image = [UIImage pin_decodedImageWithData:data skipDecodeIfPossible:skipDecode];
                    cacheCost = [image size].width * [image size].height;
                }
            }
            
            if (error == nil && image == nil && animatedImage == nil) {
                remoteImageError = [NSError errorWithDomain:PINRemoteImageManagerErrorDomain
                                                       code:PINRemoteImageManagerErrorFailedToDecodeImage
                                                   userInfo:nil];
            }
            
            if (remoteImageError == nil) {
                [strongSelf lock];
                    //call any completion blocks that are already set
                    PINRemoteImageDownloadTask *task = [strongSelf.tasks objectForKey:key];
                    [task callCompletionsWithQueue:strongSelf.callbackQueue remove:YES withImage:image animatedImage:animatedImage cached:NO error:nil];
                [strongSelf unlock];
                
                id memoryCacheObject = image;
                if (memoryCacheObject == nil) {
                    memoryCacheObject = data;
                }
                
                PINDiskCacheObjectBlock diskCacheCompletion = ^(PINDiskCache *cache, NSString *key, id<NSCoding> object, NSURL *fileURL)
                {
                    typeof(self) strongSelf = weakSelf;
                    [strongSelf lock];
                        //call any completion blocks that were added while we were caching
                        //and remove session task
                        PINRemoteImageDownloadTask *task = [strongSelf.tasks objectForKey:key];
                        [task callCompletionsWithQueue:strongSelf.callbackQueue remove:NO withImage:image animatedImage:animatedImage cached:NO error:nil];
                        [strongSelf.tasks removeObjectForKey:key];
                    [strongSelf unlock];
                };
                
                //store the UIImage in the memory cache and the NSData in the disk cache
                if (skipDecode) {
                    [strongSelf.cache.diskCache setObject:data
                                                   forKey:key
                                                    block:diskCacheCompletion];
                } else {
                    [strongSelf.cache.memoryCache setObject:memoryCacheObject
                                                     forKey:key
                                                   withCost:cacheCost
                                                      block:^(PINMemoryCache *cache, NSString *key, id object)
                    {
                        typeof(self) strongSelf = weakSelf;
                        [strongSelf.cache.diskCache setObject:data
                                                       forKey:key
                                                        block:diskCacheCompletion];
                    }];
                }
            } else {
                //call all of the completion blocks and remove the session task
                [strongSelf lock];
                    typeof(self) strongSelf = weakSelf;
                    PINRemoteImageDownloadTask *task = [strongSelf.tasks objectForKey:key];
                    [task callCompletionsWithQueue:strongSelf.callbackQueue remove:NO withImage:image animatedImage:animatedImage cached:NO error:remoteImageError];
                    [strongSelf.tasks removeObjectForKey:key];
                [strongSelf unlock];
            }
        }];
    }];
}


- (PINDataTaskOperation *)downloadDataWithURL:(NSURL *)url
                                         key:(NSString *)key
                                    priority:(PINRemoteImageManagerPriority)priority
                                  completion:(PINRemoteImageManagerDataCompletion)completion
{
    NSURLRequest *request = [NSURLRequest requestWithURL:url
                                             cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                         timeoutInterval:self.timeout];
    
    __weak typeof(self) weakSelf = self;
    PINDataTaskOperation *dataTaskOperation = [PINDataTaskOperation dataTaskOperationWithSessionManager:self.sessionManager
                                                                                              request:request
                                                                                    completionHandler:^(NSURLResponse *response, NSError *error)
    {
        typeof(self) strongSelf = weakSelf;
#if DEBUG
        [strongSelf lock];
            strongSelf.totalDownloads++;
        [strongSelf unlock];
#endif
        
#if PINRemoteImageLogging
        if (error && error.code != NSURLErrorCancelled) {
            PINLog(@"Failed downloading image: %@ with error: %@", url, error);
        } else if (error == nil && responseObject == nil) {
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
            
            completion(data, error);
        }
    }];
    
    if ([dataTaskOperation.dataTask respondsToSelector:@selector(setPriority:)]) {
        dataTaskOperation.dataTask.priority = dataTaskPriorityWithImageManagerPriority(priority);
    }
    
    dataTaskOperation.queuePriority = operationPriorityWithImageManagerPriority(priority);
    [self.urlSessionTaskQueue addOperation:dataTaskOperation];
    
    return dataTaskOperation;
}

#pragma mark - Prefetching

- (void)prefetchImagesWithURLs:(NSArray *)urls
{
    [self prefetchImagesWithURLs:urls options:PINRemoteImageManagerDownloadOptionsNone | PINRemoteImageManagerDownloadOptionsSkipEarlyCheck];
}

- (void)prefetchImagesWithURLs:(NSArray *)urls options:(PINRemoteImageManagerDownloadOptions)options
{
    for (NSURL *url in urls) {
        [self prefetchImageWithURL:url options:options];
    }
}

- (void)prefetchImageWithURL:(NSURL *)url
{
    [self prefetchImageWithURL:url options:PINRemoteImageManagerDownloadOptionsNone | PINRemoteImageManagerDownloadOptionsSkipEarlyCheck];
}

- (void)prefetchImageWithURL:(NSURL *)url options:(PINRemoteImageManagerDownloadOptions)options
{
    [self downloadImageWithURL:url
                       options:options
                      priority:PINRemoteImageManagerPriorityVeryLow
                  processorKey:nil
                     processor:nil
                       progress:nil
                    completion:nil
                     inputUUID:nil];
}

#pragma mark - Cancelation & Priority

- (void)cancelTaskWithUUID:(NSUUID *)UUID
{
    if (UUID == nil) {
        return;
    }
    PINLog(@"Attempting to cancel UUID: %@", UUID);
    __weak typeof(self) weakSelf = self;
    [_concurrentOperationQueue pin_addOperationWithQueuePriority:PINRemoteImageManagerPriorityHigh block:^
     {
        typeof(self) strongSelf = weakSelf;
        //find the task associated with the UUID. This might be spead up by storing a mapping of UUIDs to tasks
        [strongSelf lock];
            __block PINRemoteImageTask *taskToEvaluate = nil;
            __block NSString *taskKey = nil;
            [strongSelf.tasks enumerateKeysAndObjectsUsingBlock:^(NSString *key, PINRemoteImageTask *task, BOOL *stop) {
                if (task.callbackBlocks[UUID]) {
                    taskToEvaluate = task;
                    taskKey = key;
                    *stop = YES;
                }
            }];
        
            if (taskToEvaluate == nil) {
                //maybe task hasn't been added to task list yet, add it to canceled tasks
                [strongSelf.canceledTasks addObject:UUID];
            }
        
            if ([taskToEvaluate cancelWithUUID:UUID manager:strongSelf]) {
                [strongSelf.tasks removeObjectForKey:taskKey];
            }
        [strongSelf unlock];
     }];
}

- (void)setPriority:(PINRemoteImageManagerPriority)priority ofTaskWithUUID:(NSUUID *)UUID
{
    if (UUID == nil) {
        return;
    }
    PINLog(@"Setting priority of UUID: %@ priority: %lu", UUID, (unsigned long)priority);
    [self lock];
        PINRemoteImageTask *taskToEvaluate = nil;
        for (NSString *key in [self.tasks allKeys]) {
            PINRemoteImageTask *task = [self.tasks objectForKey:key];
            for (NSUUID *blockUUID in [task.callbackBlocks allKeys]) {
                if ([blockUUID isEqual:UUID]) {
                    taskToEvaluate = task;
                    break;
                }
            }
        }
    
        [taskToEvaluate setPriority:priority];
    [self unlock];
}

#pragma mark - Caching

- (void)imageFromCacheWithCacheKey:(NSString *)cacheKey
                        completion:(PINRemoteImageManagerImageCompletion)completion
{
    [self imageFromCacheWithCacheKey:cacheKey earlyCheck:YES completion:completion];
}

- (void)imageFromCacheWithCacheKey:(NSString *)cacheKey
                        earlyCheck:(BOOL)earlyCheck
                        completion:(PINRemoteImageManagerImageCompletion)completion
{
    CFTimeInterval requestTime = CACurrentMediaTime();
    
    __weak typeof(self) weakSelf = self;
    __block UIImage *image = nil;
    __block FLAnimatedImage *animatedImage = nil;
    
    void (^handleObject)(id object) = ^(id object)
    {
        image = nil;
        animatedImage = nil;
        
        if ([object isKindOfClass:[UIImage class]]) {
            image = (UIImage *)object;
        } else if ([object isKindOfClass:[NSData class]]) {
#if USE_FLANIMATED_IMAGE
            animatedImage = [[FLAnimatedImage alloc] initWithAnimatedGIFData:object];
#endif
        }
    };
    
    if (earlyCheck && [NSThread isMainThread]) {
        id object = [self.cache.memoryCache objectForKey:cacheKey];
        handleObject(object);
        completion([PINRemoteImageManagerResult imageResultWithImage:image
                                                      animatedImage:animatedImage
                                                      requestLength:CACurrentMediaTime() - requestTime
                                                              error:nil
                                                         resultType:PINRemoteImageResultTypeMemoryCache
                                                               UUID:nil]);
        return;
    }
    
    [self.cache objectForKey:cacheKey block:^(PINCache *cache, NSString *key, id object)
    {
        handleObject(object);
        typeof(self) strongSelf = weakSelf;
        dispatch_async(strongSelf.callbackQueue, ^{
            completion([PINRemoteImageManagerResult imageResultWithImage:image
                                                          animatedImage:animatedImage
                                                          requestLength:CACurrentMediaTime() - requestTime
                                                                  error:nil
                                                             resultType:PINRemoteImageResultTypeCache
                                                                   UUID:nil]);
        });
    }];
}

#pragma mark - Session Task Blocks

- (void)didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge forTask:(NSURLSessionTask *)task completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *credential))completionHandler {
	[self lock];
	if (self.authenticationChallengeHandler) {
		self.authenticationChallengeHandler(task, challenge, ^(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *credential){
			completionHandler(disposition, credential);
		});
	} else {
		completionHandler(NSURLSessionAuthChallengePerformDefaultHandling, nil);
	}
	
	[self unlock];
}

- (void)didReceiveData:(NSData *)data forTask:(NSURLSessionDataTask *)dataTask
{
    [self lock];
        PINRemoteImageDownloadTask *task = [self.tasks objectForKey:[self cacheKeyForURL:[[dataTask originalRequest] URL] processorKey:nil]];
        if (task.progressImage == nil) {
            task.progressImage = [[PINProgressiveImage alloc] init];
            task.progressImage.startTime = task.sessionTaskStartTime;
            task.progressImage.estimatedRemainingTimeThreshold = self.estimatedRemainingTimeThreshold;
            if (self.progressThresholds) {
                task.progressImage.progressThresholds = self.progressThresholds;
            }
        }
        PINProgressiveImage *progressiveImage = task.progressImage;
        BOOL hasProgressBlocks = task.hasProgressBlocks;
    [self unlock];
    
    [progressiveImage updateProgressiveImageWithData:data expectedNumberOfBytes:[dataTask countOfBytesExpectedToReceive]];

    if (hasProgressBlocks && [[self class] isiOS8OrGreater]) {
        __weak typeof(self) weakSelf = self;
        [_concurrentOperationQueue pin_addOperationWithQueuePriority:PINRemoteImageManagerPriorityLow block:^{
            typeof(self) strongSelf = weakSelf;
            UIImage *progressImage = [progressiveImage currentImage];
            if (progressImage) {
                [strongSelf lock];
                    NSString *cacheKey = [strongSelf cacheKeyForURL:[[dataTask originalRequest] URL] processorKey:nil];
                    PINRemoteImageDownloadTask *task = strongSelf.tasks[cacheKey];
                    [task callProgressWithQueue:strongSelf.callbackQueue withImage:progressImage];
                [strongSelf unlock];
            }
        }];
    }
}

- (void)didCompleteTask:(NSURLSessionTask *)task withError:(NSError *)error
{
    if (error == nil && [task isKindOfClass:[NSURLSessionDataTask class]]) {
        NSURLSessionDataTask *dataTask = (NSURLSessionDataTask *)task;
        [self lock];
            PINRemoteImageDownloadTask *task = [self.tasks objectForKey:[self cacheKeyForURL:[[dataTask originalRequest] URL] processorKey:nil]];
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

- (NSUUID *)downloadImageWithURLs:(NSArray *)urls
                          options:(PINRemoteImageManagerDownloadOptions)options
                         progress:(PINRemoteImageManagerImageCompletion)progress
                       completion:(PINRemoteImageManagerImageCompletion)completion
{
    NSUUID *UUID = [NSUUID UUID];
    if (urls.count <= 1) {
        NSURL *url = [urls firstObject];
        [self downloadImageWithURL:url
                           options:options
                          priority:PINRemoteImageManagerPriorityMedium
                      processorKey:nil
                         processor:nil
                          progress:progress
                        completion:completion
                         inputUUID:UUID];
        return UUID;
    }
    
    __weak typeof(self) weakSelf = self;
    [self.concurrentOperationQueue pin_addOperationWithQueuePriority:PINRemoteImageManagerPriorityMedium block:^{
        __block NSInteger highestQualityDownloadedIdx = -1;
        typeof(self) strongSelf = weakSelf;
        
        //check for the highest quality image already in cache. It's possible that an image is in the process of being
        //cached when this is being run. In which case two things could happen:
        // -    If network conditions dictate that a lower quality image should be downloaded than the one that is currently
        //      being cached, it will be downloaded in addition. This is not ideal behavior, worst case scenario and unlikely.
        // -    If network conditions dictate that the same quality image should be downloaded as the one being cached, no
        //      new image will be downloaded as either the caching will have finished by the time we actually request it or
        //      the task will still exist and our callback will be attached. In this case, no detrimental behavior will have
        //      occured.
        [urls enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(NSURL *url, NSUInteger idx, BOOL *stop) {
            typeof(self) strongSelf = weakSelf;
            BlockAssert([url isKindOfClass:[NSURL class]], @"url must be of type URL");
            NSString *key = [strongSelf cacheKeyForURL:url processorKey:nil];
            
            //we don't actually need the object, just need to know it exists so that we can request it later
            id objectOrFileURL = [strongSelf.cache.memoryCache objectForKey:key];
            if (objectOrFileURL == nil) {
                objectOrFileURL = [strongSelf.cache.diskCache fileURLForKey:key];
            }
            if (objectOrFileURL) {
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
                                priority:PINRemoteImageManagerPriorityMedium
                            processorKey:nil
                               processor:nil
                                progress:progress
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
    }];
    return UUID;
}

#pragma mark - Helpers


+ (BOOL)isiOS8OrGreater
{
    static BOOL isiOS8OrGreater;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *reqSysVer = @"8";
        NSString *currSysVer = [[UIDevice currentDevice] systemVersion];
        if ([currSysVer compare:reqSysVer options:NSNumericSearch] != NSOrderedAscending)
            isiOS8OrGreater = YES;
    });
    return isiOS8OrGreater;
}

- (NSString *)cacheKeyForURL:(NSURL *)url processorKey:(NSString *)processorKey
{
    NSString *cacheKey = [url absoluteString];
    if (processorKey.length > 0) {
        cacheKey = [cacheKey stringByAppendingString:[NSString stringWithFormat:@"-<%@>", processorKey]];
    }
    return cacheKey;
}

@end

@implementation NSOperationQueue (PINRemoteImageManager)

- (void)pin_addOperationWithQueuePriority:(PINRemoteImageManagerPriority)priority block:(void (^)(void))block
{
    NSBlockOperation *operation = [NSBlockOperation blockOperationWithBlock:block];
    operation.queuePriority = operationPriorityWithImageManagerPriority(priority);
#if __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_8_0
    if ([PINRemoteImageManager isiOS8OrGreater]) {
        operation.qualityOfService = NSOperationQualityOfServiceBackground;
    } else {
        operation.threadPriority = 0.2;
    }
#else
    operation.qualityOfService = NSOperationQualityOfServiceBackground;
#endif
    [self addOperation:operation];
}

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
