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

#import <objc/runtime.h>

#import "PINAlternateRepresentationProvider.h"
#import "PINRemoteImage.h"
#import "PINRemoteImageManagerConfiguration.h"
#import "PINRemoteLock.h"
#import "PINProgressiveImage.h"
#import "PINRemoteImageCallbacks.h"
#import "PINRemoteImageTask.h"
#import "PINRemoteImageProcessorTask.h"
#import "PINRemoteImageDownloadTask.h"
#import "PINResume.h"
#import "PINRemoteImageMemoryContainer.h"
#import "PINRemoteImageCaching.h"
#import "PINRequestRetryStrategy.h"
#import "PINRemoteImageDownloadQueue.h"
#import "PINRequestRetryStrategy.h"
#import "PINSpeedRecorder.h"
#import "PINURLSessionManager.h"

#import "NSData+ImageDetectors.h"
#import "PINImage+DecodedImage.h"
#import "PINImage+ScaledImage.h"
#import "PINRemoteImageManager+Private.h"
#import "NSHTTPURLResponse+MaxAge.h"

#if USE_PINCACHE
#import "PINCache+PINRemoteImageCaching.h"
#else
#import "PINRemoteImageBasicCache.h"
#endif


#define PINRemoteImageManagerDefaultTimeout 30.0
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

// Reference: https://github.com/TextureGroup/Texture/blob/5dd5611/Source/Private/ASInternalHelpers.m#L60
BOOL PINRemoteImageManagerSubclassOverridesSelector(Class subclass, SEL selector)
{
    Class superclass = [PINRemoteImageManager class];
    if (superclass == subclass) return NO; // Even if the class implements the selector, it doesn't override itself.
    Method superclassMethod = class_getInstanceMethod(superclass, selector);
    Method subclassMethod = class_getInstanceMethod(subclass, selector);
    return (superclassMethod != subclassMethod);
}

NSErrorDomain const PINRemoteImageManagerErrorDomain = @"PINRemoteImageManagerErrorDomain";
NSString * const PINRemoteImageCacheKey = @"cacheKey";
NSString * const PINRemoteImageCacheKeyResumePrefix = @"R-";
typedef void (^PINRemoteImageManagerDataCompletion)(NSData *data, NSURLResponse *response, NSError *error);

@interface PINRemoteImageManager () <PINURLSessionManagerDelegate>
{
  dispatch_queue_t _callbackQueue;
  PINRemoteLock *_lock;
  PINOperationQueue *_concurrentOperationQueue;
  PINRemoteImageDownloadQueue *_urlSessionTaskQueue;
  
  // Necesarry to have a strong reference to _defaultAlternateRepresentationProvider because _alternateRepProvider is __weak
  PINAlternateRepresentationProvider *_defaultAlternateRepresentationProvider;
  __weak PINAlternateRepresentationProvider *_alternateRepProvider;
  NSURLSessionConfiguration *_sessionConfiguration;

}

@property (nonatomic, strong) id<PINRemoteImageCaching> cache;
@property (nonatomic, strong) PINURLSessionManager *sessionManager;
@property (nonatomic, strong) NSMutableDictionary <NSString *, __kindof PINRemoteImageTask *> *tasks;
@property (nonatomic, strong) NSHashTable <NSUUID *> *canceledTasks;
@property (nonatomic, strong) NSHashTable <NSUUID *> *UUIDs;
@property (nonatomic, strong) NSArray <NSNumber *> *progressThresholds;
@property (nonatomic, assign) BOOL shouldBlurProgressive;
@property (nonatomic, assign) CGSize maxProgressiveRenderSize;
@property (nonatomic, assign) NSTimeInterval estimatedRemainingTimeThreshold;
@property (nonatomic, strong) dispatch_queue_t callbackQueue;
@property (nonatomic, strong) PINOperationQueue *concurrentOperationQueue;
@property (nonatomic, strong) PINRemoteImageDownloadQueue *urlSessionTaskQueue;
@property (nonatomic, assign) float highQualityBPSThreshold;
@property (nonatomic, assign) float lowQualityBPSThreshold;
@property (nonatomic, assign) BOOL shouldUpgradeLowQualityImages;
@property (nonatomic, strong) PINRemoteImageManagerMetrics metricsCallback API_AVAILABLE(macosx(10.12), ios(10.0), watchos(3.0), tvos(10.0));
@property (nonatomic, copy) PINRemoteImageManagerAuthenticationChallenge authenticationChallengeHandler;
@property (nonatomic, copy) id<PINRequestRetryStrategy> (^retryStrategyCreationBlock)(void);
@property (nonatomic, copy) PINRemoteImageManagerRequestConfigurationHandler requestConfigurationHandler;
@property (nonatomic, strong) NSMutableDictionary <NSString *, NSString *> *httpHeaderFields;
@property (nonatomic, readonly) BOOL diskCacheTTLIsEnabled;
@property (nonatomic, readonly) BOOL memoryCacheTTLIsEnabled;
#if DEBUG
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

- (instancetype)initWithSessionConfiguration:(NSURLSessionConfiguration *)sessionConfiguration
{
    return [self initWithSessionConfiguration:sessionConfiguration alternativeRepresentationProvider:nil];
}

- (instancetype)initWithSessionConfiguration:(NSURLSessionConfiguration *)sessionConfiguration alternativeRepresentationProvider:(id <PINRemoteImageManagerAlternateRepresentationProvider>)alternateRepProvider
{
    return [self initWithSessionConfiguration:sessionConfiguration alternativeRepresentationProvider:alternateRepProvider imageCache:nil managerConfiguration:nil];
}

- (nonnull instancetype)initWithSessionConfiguration:(nullable NSURLSessionConfiguration *)sessionConfiguration
                   alternativeRepresentationProvider:(nullable id <PINRemoteImageManagerAlternateRepresentationProvider>)alternateRepDelegate
                                          imageCache:(nullable id<PINRemoteImageCaching>)imageCache {
    return [self initWithSessionConfiguration:sessionConfiguration alternativeRepresentationProvider:alternateRepDelegate imageCache:imageCache managerConfiguration:nil];
}

-(nonnull instancetype)initWithSessionConfiguration:(NSURLSessionConfiguration *)sessionConfiguration
                  alternativeRepresentationProvider:(id<PINRemoteImageManagerAlternateRepresentationProvider>)alternateRepProvider
                                         imageCache:(id<PINRemoteImageCaching>)imageCache
                               managerConfiguration:(nullable PINRemoteImageManagerConfiguration *)managerConfiguration
{
    if (self = [super init]) {
        PINRemoteImageManagerConfiguration *configuration = managerConfiguration;
        if (!configuration) {
            configuration = [[PINRemoteImageManagerConfiguration alloc] init];
        }
        
        if (imageCache) {
            self.cache = imageCache;
        } else if (PINRemoteImageManagerSubclassOverridesSelector([self class], @selector(defaultImageCache))) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
            self.cache = [self defaultImageCache];
#pragma clang diagnostic pop
        } else {
            self.cache = [[self class] defaultImageCache];
        }
        
        if ([self.cache respondsToSelector:@selector(setObjectOnDisk:forKey:withAgeLimit:)] &&
                [self.cache respondsToSelector:@selector(setObjectInMemory:forKey:withCost:withAgeLimit:)] &&
                [self.cache respondsToSelector:@selector(diskCacheIsTTLCache)] &&
                [self.cache respondsToSelector:@selector(memoryCacheIsTTLCache)]) {
            _diskCacheTTLIsEnabled = [self.cache diskCacheIsTTLCache];
            _memoryCacheTTLIsEnabled = [self.cache memoryCacheIsTTLCache];
        }
        
        _sessionConfiguration = [sessionConfiguration copy];
        if (!_sessionConfiguration) {
            _sessionConfiguration = [NSURLSessionConfiguration ephemeralSessionConfiguration];
            _sessionConfiguration.timeoutIntervalForRequest = PINRemoteImageManagerDefaultTimeout;
            _sessionConfiguration.requestCachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
            _sessionConfiguration.URLCache = nil;
        }
        _sessionConfiguration.HTTPMaximumConnectionsPerHost = PINRemoteImageHTTPMaximumConnectionsPerHost;
        
        _callbackQueue = dispatch_queue_create("PINRemoteImageManagerCallbackQueue", DISPATCH_QUEUE_CONCURRENT);
        _lock = [[PINRemoteLock alloc] initWithName:@"PINRemoteImageManager"];
        
        _concurrentOperationQueue = [[PINOperationQueue alloc] initWithMaxConcurrentOperations: configuration.maxConcurrentOperations];
        _urlSessionTaskQueue = [PINRemoteImageDownloadQueue queueWithMaxConcurrentDownloads:configuration.maxConcurrentDownloads];
        
        self.sessionManager = [[PINURLSessionManager alloc] initWithSessionConfiguration:_sessionConfiguration];
        self.sessionManager.delegate = self;
        
        self.estimatedRemainingTimeThreshold = configuration.estimatedRemainingTimeThreshold;
        
        _highQualityBPSThreshold = configuration.highQualityBPSThreshold;
        _lowQualityBPSThreshold = configuration.lowQualityBPSThreshold;
        _shouldUpgradeLowQualityImages = configuration.shouldUpgradeLowQualityImages;
        _shouldBlurProgressive = configuration.shouldBlurProgressive;
        _maxProgressiveRenderSize = configuration.maxProgressiveRenderSize;
        self.tasks = [[NSMutableDictionary alloc] init];
        self.canceledTasks = [[NSHashTable alloc] initWithOptions:NSHashTableWeakMemory capacity:5];
        self.UUIDs = [NSHashTable weakObjectsHashTable];
        
        if (alternateRepProvider == nil) {
            _defaultAlternateRepresentationProvider = [[PINAlternateRepresentationProvider alloc] init];
            alternateRepProvider = _defaultAlternateRepresentationProvider;
        }
        _alternateRepProvider = alternateRepProvider;
        __weak typeof(self) weakSelf = self;
        _retryStrategyCreationBlock = ^id<PINRequestRetryStrategy>{
            return [weakSelf defaultRetryStrategy];
        };
        _httpHeaderFields = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (id<PINRequestRetryStrategy>)defaultRetryStrategy {
    return [[PINRequestExponentialRetryStrategy alloc] initWithRetryMaxCount:3 delayBase:4];
}

- (void)dealloc
{
    [self.sessionManager invalidateSessionAndCancelTasks];
}

- (id<PINRemoteImageCaching>)defaultImageCache {
    return [PINRemoteImageManager defaultImageCache];
}

+ (id<PINRemoteImageCaching>)defaultImageCache {
    return [PINRemoteImageManager defaultImageCacheEnablingTtl:NO];
}

+ (id<PINRemoteImageCaching>)defaultImageTtlCache {
    return [PINRemoteImageManager defaultImageCacheEnablingTtl:YES];
}

+ (id<PINRemoteImageCaching>)defaultImageCacheEnablingTtl:(BOOL)enableTtl
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
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSURL *dstURL = [[[NSURL alloc] initFileURLWithPath:NSTemporaryDirectory()] URLByAppendingPathComponent:kPINRemoteImageDiskCacheName];
        [fileManager moveItemAtURL:diskCacheURL toURL:dstURL error:nil];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [fileManager removeItemAtURL:dstURL error:nil];
        });
        [pinDefaults setInteger:kPINRemoteImageDiskCacheVersion forKey:kPINRemoteImageDiskCacheVersionKey];
    }

    PINCache *pinCache = [[PINCache alloc] initWithName:kPINRemoteImageDiskCacheName rootPath:cacheURLRoot serializer:^NSData * _Nonnull(id<NSCoding>  _Nonnull object, NSString * _Nonnull key) {
        id <NSCoding, NSObject> obj = (id <NSCoding, NSObject>)object;
        if ([key hasPrefix:PINRemoteImageCacheKeyResumePrefix]) {
            return [NSKeyedArchiver archivedDataWithRootObject:obj];
        }
        return (NSData *)object;
    } deserializer:^id<NSCoding> _Nonnull(NSData * _Nonnull data, NSString * _Nonnull key) {
        if ([key hasPrefix:PINRemoteImageCacheKeyResumePrefix]) {
            return [NSKeyedUnarchiver unarchiveObjectWithData:data];
        }
        return data;
    } keyEncoder:nil keyDecoder:nil ttlCache:enableTtl];

    return pinCache;
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

- (void)setRequestConfiguration:(PINRemoteImageManagerRequestConfigurationHandler)configurationBlock {
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        typeof(self) strongSelf = weakSelf;
        [strongSelf lock];
            strongSelf.requestConfigurationHandler = configurationBlock;
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
    NSAssert(maxNumberOfConcurrentDownloads <= PINRemoteImageHTTPMaximumConnectionsPerHost, @"maxNumberOfConcurrentDownloads must be less than or equal to %d", PINRemoteImageHTTPMaximumConnectionsPerHost);
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

- (void)setMetricsCallback:(nullable PINRemoteImageManagerMetrics)metricsCallback completion:(nullable dispatch_block_t)completion
{
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        typeof(self) strongSelf = weakSelf;
        [self lock];
            strongSelf.metricsCallback = metricsCallback;
        [self unlock];
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
                        progressImage:progressImage
                     progressDownload:nil
                           completion:completion];
}

- (NSUUID *)downloadImageWithURL:(NSURL *)url
                         options:(PINRemoteImageManagerDownloadOptions)options
                progressDownload:(PINRemoteImageManagerProgressDownload)progressDownload
                      completion:(PINRemoteImageManagerImageCompletion)completion
{
    return [self downloadImageWithURL:url
                              options:options
                        progressImage:nil
                     progressDownload:progressDownload
                           completion:completion];
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
                        progressImage:progressImage
                     progressDownload:progressDownload
                           completion:completion];
}

- (nullable NSUUID *)downloadImageWithURL:(nonnull NSURL *)url
                                  options:(PINRemoteImageManagerDownloadOptions)options
                                 priority:(PINRemoteImageManagerPriority)priority
                            progressImage:(PINRemoteImageManagerImageCompletion)progressImage
                         progressDownload:(nullable PINRemoteImageManagerProgressDownload)progressDownload
                               completion:(nullable PINRemoteImageManagerImageCompletion)completion;
{
    return [self downloadImageWithURL:url
                              options:options
                             priority:priority
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
    
    [_concurrentOperationQueue scheduleOperation:^
    {
        [self lock];
            //check canceled tasks first
            if ([self.canceledTasks containsObject:UUID]) {
                PINLog(@"skipping starting %@ because it was canceled.", UUID);
                [self unlock];
                return;
            }
        
            PINRemoteImageTask *task = [self.tasks objectForKey:key];
            BOOL taskExisted = NO;
            if (task == nil) {
                task = [[taskClass alloc] initWithManager:self];
                PINLog(@"Task does not exist creating with key: %@, URL: %@, UUID: %@, task: %p", key, url, UUID, task);
    #if PINRemoteImageLogging
                task.key = key;
    #endif
            } else {
                taskExisted = YES;
                PINLog(@"Task exists, attaching with key: %@, URL: %@, UUID: %@, task: %@", key, url, UUID, task);
            }
            [task addCallbacksWithCompletionBlock:completion progressImageBlock:progressImage progressDownloadBlock:progressDownload withUUID:UUID];
            [self.tasks setObject:task forKey:key];
            // Relax :), task retain the UUID for us, it's ok to have a weak reference to UUID here.
            [self.UUIDs addObject:UUID];
        
            NSAssert(taskClass == [task class], @"Task class should be the same!");
        [self unlock];
        
        if (taskExisted == NO) {
            [self.concurrentOperationQueue scheduleOperation:^
             {
                 [self objectForKey:key options:options completion:^(BOOL found, BOOL valid, PINImage *image, id alternativeRepresentation) {
                     if (found) {
                         if (valid) {
                             [self callCompletionsWithKey:key image:image alternativeRepresentation:alternativeRepresentation cached:YES response:nil error:nil finalized:YES];
                         } else {
                             //Remove completion and try again
                             [self lock];
                                 PINRemoteImageTask *task = [self.tasks objectForKey:key];
                                 [task removeCallbackWithUUID:UUID];
                                 if (task.callbackBlocks.count == 0) {
                                     [self.tasks removeObjectForKey:key];
                                 }
                             [self unlock];
                             
                             //Skip early check
                             [self downloadImageWithURL:url
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
                             [self downloadImageWithURL:url
                                                options:options
                                               priority:priority
                                                    key:key
                                              processor:processor
                                                   UUID:UUID];
                         } else if ([taskClass isSubclassOfClass:[PINRemoteImageDownloadTask class]]) {
                             //continue downloading
                             [self downloadImageWithURL:url
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
                [strongSelf callCompletionsWithKey:key image:image alternativeRepresentation:nil cached:NO response:result.response error:error finalized:NO];
              
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
                
                [strongSelf callCompletionsWithKey:key image:image alternativeRepresentation:nil cached:NO response:result.response error:error finalized:YES];
            } else {
                if (error == nil) {
                    error = [NSError errorWithDomain:PINRemoteImageManagerErrorDomain
                                                code:PINRemoteImageManagerErrorFailedToFetchImageForProcessing
                                            userInfo:nil];
                }

                [strongSelf callCompletionsWithKey:key image:nil alternativeRepresentation:nil cached:NO response:result.response error:error finalized:YES];
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
    PINResume *resume = nil;
    if ((options & PINRemoteImageManagerDownloadOptionsIgnoreCache) == NO) {
        NSString *resumeKey = [self resumeCacheKeyForURL:url];
        resume = [self.cache objectFromDiskForKey:resumeKey];
        [self.cache removeObjectForKey:resumeKey completion:nil];
    }
    
    [self lock];
        PINRemoteImageDownloadTask *task = [self.tasks objectForKey:key];
    [self unlock];
    
    [task scheduleDownloadWithRequest:[self requestWithURL:url key:key]
                               resume:resume
                            skipRetry:(options & PINRemoteImageManagerDownloadOptionsSkipRetry)
                             priority:priority
                    completionHandler:^(NSData *data, NSURLResponse *response, NSError *error)
    {
        [self->_concurrentOperationQueue scheduleOperation:^
        {
            NSError *remoteImageError = error;
            PINImage *image = nil;
            id alternativeRepresentation = nil;
            NSNumber *maxAge = nil;
            if (remoteImageError == nil) {
                BOOL ignoreHeaders = (options & PINRemoteImageManagerDownloadOptionsIgnoreCacheControlHeaders) != 0;
                if ((self.diskCacheTTLIsEnabled || self.memoryCacheTTLIsEnabled) && !ignoreHeaders) {
                    // examine Cache-Control headers (https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Cache-Control)
                    if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
                        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *) response;
                        maxAge = [httpResponse findMaxAge];
                    }
                }
                // Stores the object in the cache.
                [self materializeAndCacheObject:data cacheInDisk:data additionalCost:0 maxAge:maxAge url:url key:key options:options outImage:&image outAltRep:&alternativeRepresentation];
             }

            if (error == nil && image == nil && alternativeRepresentation == nil) {
                 remoteImageError = [NSError errorWithDomain:PINRemoteImageManagerErrorDomain
                                                        code:PINRemoteImageManagerErrorFailedToDecodeImage
                                                    userInfo:nil];
             }

            [self callCompletionsWithKey:key image:image alternativeRepresentation:alternativeRepresentation cached:NO response:response error:remoteImageError finalized:YES];
         } withPriority:operationPriorityWithImageManagerPriority(priority)];
    }];
}

-(BOOL)insertImageDataIntoCache:(nonnull NSData*)data
                        withURL:(nonnull NSURL *)url
                   processorKey:(nullable NSString *)processorKey
                 additionalCost:(NSUInteger)additionalCost
{
  
  if (url != nil) {
    NSString *key = [self cacheKeyForURL:url processorKey:processorKey];
    
    PINRemoteImageManagerDownloadOptions options = PINRemoteImageManagerDownloadOptionsSkipDecode | PINRemoteImageManagerDownloadOptionsSkipEarlyCheck;
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
        PINRemoteImageManagerResult *result = [PINRemoteImageManagerResult imageResultWithImage:image
                                                                      alternativeRepresentation:alternativeRepresentation
                                                                                  requestLength:0
                                                                                     resultType:resultType
                                                                                           UUID:nil
                                                                                       response:nil
                                                                                          error:error];
        if (allowEarlyReturn && [NSThread isMainThread]) {
            completion(result);
        } else {
            dispatch_async(self.callbackQueue, ^{
                completion(result);
            });
        }
        return YES;
    }
    return NO;
}

- (NSURLRequest *)requestWithURL:(NSURL *)url key:(NSString *)key
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];

    NSMutableDictionary *headers = [self.httpHeaderFields mutableCopy];
    
    if (headers.count > 0) {
        request.allHTTPHeaderFields = headers;
    }
    
    if (_requestConfigurationHandler) {
        request = [_requestConfigurationHandler(request) mutableCopy];
    }
    
    [NSURLProtocol setProperty:key forKey:PINRemoteImageCacheKey inRequest:request];
    
    return request;
}

- (void)callCompletionsWithKey:(NSString *)key
                         image:(PINImage *)image
     alternativeRepresentation:(id)alternativeRepresentation
                        cached:(BOOL)cached
                      response:(NSURLResponse *)response
                         error:(NSError *)error
                     finalized:(BOOL)finalized
{
    [self lock];
        PINRemoteImageDownloadTask *task = [self.tasks objectForKey:key];
        [task callCompletionsWithImage:image alternativeRepresentation:alternativeRepresentation cached:cached response:response error:error remove:!finalized];
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
    return [self prefetchImagesWithURLs:urls options:options priority:PINRemoteImageManagerPriorityLow];
}

- (NSArray<NSUUID *> *)prefetchImagesWithURLs:(NSArray <NSURL *> *)urls options:(PINRemoteImageManagerDownloadOptions)options priority:(PINRemoteImageManagerPriority)priority
{
    NSMutableArray *tasks = [NSMutableArray arrayWithCapacity:urls.count];
    for (NSURL *url in urls) {
        NSUUID *task = [self prefetchImageWithURL:url options:options priority:priority];
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
    return [self prefetchImageWithURL:url options:options priority:PINRemoteImageManagerPriorityLow];
}

- (NSUUID *)prefetchImageWithURL:(NSURL *)url options:(PINRemoteImageManagerDownloadOptions)options priority:(PINRemoteImageManagerPriority)priority
{
    return [self downloadImageWithURL:url
                              options:options
                             priority:priority
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
    [_concurrentOperationQueue scheduleOperation:^{
        PINResume *resume = nil;
        [self lock];
            NSString *taskKey = nil;
            PINRemoteImageTask *taskToEvaluate = [self _locked_taskForUUID:UUID key:&taskKey];
            
            if (taskToEvaluate == nil) {
                //maybe task hasn't been added to task list yet, add it to canceled tasks.
                //there's no need to ever remove a UUID from canceledTasks because it is weak.
                [self.canceledTasks addObject:UUID];
            }
            
            if ([taskToEvaluate cancelWithUUID:UUID resume:storeResumeData ? &resume : NULL]) {
                [self.tasks removeObjectForKey:taskKey];
            }
        [self unlock];
        
        if (resume) {
            //store resume data away, only download tasks currently return resume data
            [self storeResumeData:resume forURL:[(PINRemoteImageDownloadTask *)taskToEvaluate URL]];
        }
    } withPriority:PINOperationQueuePriorityHigh];
}

- (void)cancelAllTasks
{
    [self cancelAllTasksAndStoreResumeData:NO];
}

- (void)cancelAllTasksAndStoreResumeData:(BOOL)storeResumeData
{
    [_concurrentOperationQueue scheduleOperation:^{
        [self lock];
            NSArray<NSUUID *> *uuidToTask = [self.UUIDs allObjects];
        [self unlock];
        for (NSUUID *uuid in uuidToTask) {
            [self cancelTaskWithUUID:uuid storeResumeData:storeResumeData];
        }
    } withPriority:PINOperationQueuePriorityHigh];
}

- (void)setPriority:(PINRemoteImageManagerPriority)priority ofTaskWithUUID:(NSUUID *)UUID
{
    if (UUID == nil) {
        return;
    }
    PINLog(@"Setting priority of UUID: %@ priority: %lu", UUID, (unsigned long)priority);
    [_concurrentOperationQueue scheduleOperation:^{
        [self lock];
            PINRemoteImageTask *task = [self _locked_taskForUUID:UUID key:NULL];
            [task setPriority:priority];
        [self unlock];
    } withPriority:PINOperationQueuePriorityHigh];
}

- (void)setProgressImageCallback:(nullable PINRemoteImageManagerImageCompletion)progressImageCallback ofTaskWithUUID:(nonnull NSUUID *)UUID
{
    if (UUID == nil) {
        return;
    }
    
    PINLog(@"setting progress block of UUID: %@ progressBlock: %@", UUID, progressImageCallback);
    [_concurrentOperationQueue scheduleOperation:^{
        [self lock];
            PINRemoteImageTask *task = [self _locked_taskForUUID:UUID key:NULL];
            if ([task isKindOfClass:[PINRemoteImageDownloadTask class]]) {
                PINRemoteImageCallbacks *callbacks = task.callbackBlocks[UUID];
                callbacks.progressImageBlock = progressImageCallback;
            }
        [self unlock];
    } withPriority:PINOperationQueuePriorityHigh];
}

- (void)setRetryStrategyCreationBlock:(id<PINRequestRetryStrategy> (^)(void))retryStrategyCreationBlock {
    [_concurrentOperationQueue scheduleOperation:^{
        [self lock];
            self->_retryStrategyCreationBlock = retryStrategyCreationBlock;
        [self unlock];
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
        if (result.image && result.error == nil) {
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
                                                              resultType:PINRemoteImageResultTypeCache
                                                                    UUID:nil
                                                                response:nil
                                                                   error:error]);
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
                                                  resultType:PINRemoteImageResultTypeMemoryCache
                                                        UUID:nil
                                                    response:nil
                                                       error:error];
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
    [task didReceiveResponse:response];
}

- (void)didReceiveData:(NSData *)data forTask:(NSURLSessionTask *)dataTask
{
    [self lock];
        NSString *cacheKey = [NSURLProtocol propertyForKey:PINRemoteImageCacheKey inRequest:dataTask.originalRequest];
        PINRemoteImageDownloadTask *task = [self.tasks objectForKey:cacheKey];
    [self unlock];
    [task didReceiveData:data];
}

- (void)didCollectMetrics:(nonnull NSURLSessionTaskMetrics *)metrics forURL:(nonnull NSURL *)url API_AVAILABLE(macosx(10.12), ios(10.0), watchos(3.0), tvos(10.0))
{
    [self lock];
        if (self.metricsCallback) {
            self.metricsCallback(url, metrics);
        }
    [self unlock];
}

#pragma mark - QOS

- (NSUUID *)downloadImageWithURLs:(NSArray <NSURL *> *)urls
                          options:(PINRemoteImageManagerDownloadOptions)options
                    progressImage:(PINRemoteImageManagerImageCompletion)progressImage
                       completion:(PINRemoteImageManagerImageCompletion)completion
{
    return [self downloadImageWithURLs:urls
                               options:options
                         progressImage:progressImage
                      progressDownload:nil
                            completion:completion];
}

- (nullable NSUUID *)downloadImageWithURLs:(nonnull NSArray <NSURL *> *)urls
                                   options:(PINRemoteImageManagerDownloadOptions)options
                             progressImage:(nullable PINRemoteImageManagerImageCompletion)progressImage
                          progressDownload:(nullable PINRemoteImageManagerProgressDownload)progressDownload
                                completion:(nullable PINRemoteImageManagerImageCompletion)completion
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
                  progressDownload:progressDownload
                        completion:completion
                         inputUUID:UUID];
        return UUID;
    }
    
    [self.concurrentOperationQueue scheduleOperation:^{
        __block NSInteger highestQualityDownloadedIdx = -1;
        
        //check for the highest quality image already in cache. It's possible that an image is in the process of being
        //cached when this is being run. In which case two things could happen:
        // -    If network conditions dictate that a lower quality image should be downloaded than the one that is currently
        //      being cached, it will be downloaded in addition. This is not ideal behavior, worst case scenario and unlikely.
        // -    If network conditions dictate that the same quality image should be downloaded as the one being cached, no
        //      new image will be downloaded as either the caching will have finished by the time we actually request it or
        //      the task will still exist and our callback will be attached. In this case, no detrimental behavior will have
        //      occurred.
        [urls enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(NSURL *url, NSUInteger idx, BOOL *stop) {
            NSAssert([url isKindOfClass:[NSURL class]], @"url must be of type URL");
            NSString *cacheKey = [self cacheKeyForURL:url processorKey:nil];
            
            //we don't actually need the object, just need to know it exists so that we can request it later
            BOOL hasObject = [self.cache objectExistsForKey:cacheKey];
            
            if (hasObject) {
                highestQualityDownloadedIdx = idx;
                *stop = YES;
            }
        }];
        
        [self lock];
            float highQualityQPSThreshold = [self highQualityBPSThreshold];
            float lowQualityQPSThreshold = [self lowQualityBPSThreshold];
            BOOL shouldUpgradeLowQualityImages = [self shouldUpgradeLowQualityImages];
        [self unlock];
        
        NSUInteger desiredImageURLIdx = [PINSpeedRecorder appropriateImageIdxForURLsGivenHistoricalNetworkConditions:urls
                                                                                              lowQualityQPSThreshold:lowQualityQPSThreshold
                                                                                             highQualityQPSThreshold:highQualityQPSThreshold];
        
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
        
        [self downloadImageWithURL:downloadURL
                                 options:options
                                priority:PINRemoteImageManagerPriorityDefault
                            processorKey:nil
                               processor:nil
                           progressImage:progressImage
                        progressDownload:progressDownload
                              completion:^(PINRemoteImageManagerResult *result) {
                                  //clean out any lower quality images from the cache
                                  for (NSInteger idx = downloadIdx - 1; idx >= 0; idx--) {
                                      [[self cache] removeObjectForKey:[self cacheKeyForURL:[urls objectAtIndex:idx] processorKey:nil]];
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

- (BOOL)materializeAndCacheObject:(id)object
                      cacheInDisk:(NSData *)diskData
                   additionalCost:(NSUInteger)additionalCost
                              url:(NSURL *)url
                              key:(NSString *)key
                          options:(PINRemoteImageManagerDownloadOptions)options
                         outImage:(PINImage **)outImage
                        outAltRep:(id *)outAlternateRepresentation {
    return [self materializeAndCacheObject:object cacheInDisk:diskData additionalCost:additionalCost maxAge:nil url:url key:key options:options outImage:outImage outAltRep:outAlternateRepresentation];
}

//takes the object from the cache and returns an image or animated image.
//if it's a non-alternative representation and skipDecode is not set it also decompresses the image.
- (BOOL)materializeAndCacheObject:(id)object
                      cacheInDisk:(NSData *)diskData
                   additionalCost:(NSUInteger)additionalCost
                           maxAge:(NSNumber *)maxAge
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

    // maxAge set to 0 means that images should not be stored at all.
    BOOL doNotCache = (maxAge != nil && [maxAge integerValue] == 0);

    // There is no HTTP header that can be sent to indicate "infinite". However not setting a value at all, which in
    // our case is represented by maxAge == nil, effectively means that.
    BOOL cacheIndefinitely = (maxAge == nil);

    if (!doNotCache) {
        if (updateMemoryCache) {
            [container.lock lockWithBlock:^{
                NSUInteger cacheCost = additionalCost;
                cacheCost += [container.data length];
                CGImageRef imageRef = container.image.CGImage;
                NSAssert(container.image == nil || imageRef != NULL, @"We only cache a decompressed image if we decompressed it ourselves. In that case, it should be backed by a CGImageRef.");
                if (imageRef) {
                    cacheCost += CGImageGetHeight(imageRef) * CGImageGetBytesPerRow(imageRef);
                }
                if (!self.memoryCacheTTLIsEnabled || cacheIndefinitely) {
                    [self.cache setObjectInMemory:container forKey:key withCost:cacheCost];
                } else {
                    [self.cache setObjectInMemory:container forKey:key withCost:cacheCost withAgeLimit:[maxAge integerValue]];
                }
            }];
        }

        if (diskData) {
            if (!self.diskCacheTTLIsEnabled || cacheIndefinitely) {
                // with an unset (nil) maxAge, or a cache that is not _isTtlCache, behave as before (will use cache global behavior)
                [self.cache setObjectOnDisk:diskData forKey:key];
            } else {
                [self.cache setObjectOnDisk:diskData forKey:key withAgeLimit:[maxAge integerValue]];
            }
        }
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
    //The resume key must not be hashed, it is used to decide whether or not to decode from the disk cache.
    if (resume) {
      cacheKey = [PINRemoteImageCacheKeyResumePrefix stringByAppendingString:cacheKey];
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
    [self.cache setObjectOnDisk:resume forKey:resumeKey];
}

/// Attempt to find the task with the callbacks for the given uuid
- (nullable PINRemoteImageTask *)_locked_taskForUUID:(NSUUID *)uuid key:(NSString * __strong *)outKey
{
    __block PINRemoteImageTask *result = nil;
    __block NSString *strongKey = nil;

    [self.tasks enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, __kindof PINRemoteImageTask * _Nonnull task, BOOL * _Nonnull stop) {
        // If this isn't our task, just return.
        if (task.callbackBlocks[uuid] == nil) {
            return;
        }

        // Found it! Save our results and end enumeration
        result = task;
        strongKey = key;
        *stop = YES;
    }];
    
    if (outKey != nil) {
        *outKey = strongKey;
    }
    return result;
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
