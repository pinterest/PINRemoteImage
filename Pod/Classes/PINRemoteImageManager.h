//
//  PINRemoteImageManager.h
//  Pods
//
//  Created by Garrett Moon on 8/17/14.
//
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "PINRemoteImageManagerResult.h"

@class FLAnimatedImage;
@class PINCache;
@class PINRemoteImageManagerResult;

/*
 @warning when using in extension or watch extension, define PIN_APP_EXTENSIONS=1
 */

extern NSString * const PINRemoteImageManagerErrorDomain;

/**
 Error codes returned by PINRemoteImage
 */
typedef NS_ENUM(NSUInteger, PINRemoteImageManagerError) {
    /** The image failed to decode */
    PINRemoteImageManagerErrorFailedToDecodeImage = 1,
    /** The image could not be downloaded and therefore could not be processed */
    PINRemoteImageManagerErrorFailedToFetchImageForProcessing = 2,
    /** The image returned by the processor block was nil */
    PINRemoteImageManagerErrorFailedToProcessImage = 3,
};

/**
 Options with which to download and process images
 */
typedef NS_ENUM(NSUInteger, PINRemoteImageManagerDownloadOptions) {
    /** Download and process with default options (no other options set) */
    PINRemoteImageManagerDownloadOptionsNone = 0,
    /** Regardless of the image type downloaded, return UIImages and *not* FLAnimatedImage */
    PINRemoteImageManagerDownloadOptionsIgnoreGIFs = 1,
    /** Skip decoding the image before returning. This means smaller images returned, but images will be decoded on the main thread when set on an image view */
    PINRemoteImageManagerDownloadOptionsSkipDecode = 1 << 1,
    /** Skip the early check of the memory cache */
    PINRemoteImageManagerDownloadOptionsSkipEarlyCheck = 1 << 2,
    /** Save processed images as JPEGs in the cache. The default is PNG to support transparency */
    PINRemoteImageManagerSaveProcessedImageAsJPEG = 1 << 3,
};

/**
 Priority to download and process image at.
 */
typedef NS_ENUM(NSUInteger, PINRemoteImageManagerPriority) {
    /** Very low priority */
    PINRemoteImageManagerPriorityVeryLow = 0,
    /** Low priority */
    PINRemoteImageManagerPriorityLow,
    /** Medium priority */
    PINRemoteImageManagerPriorityMedium,
    /** High priority */
    PINRemoteImageManagerPriorityHigh,
    /** Very high priority */
    PINRemoteImageManagerPriorityVeryHigh,
};

NSOperationQueuePriority operationPriorityWithImageManagerPriority(PINRemoteImageManagerPriority priority);
float dataTaskPriorityWithImageManagerPriority(PINRemoteImageManagerPriority priority);

/**
 Completion called for many PINRemoteImage tasks as well as progress updates. Passed in a PINRemoteImageManagerResult.
 
 @param result PINRemoteImageManagerResult which contains the downloaded image.
 */
typedef void (^PINRemoteImageManagerImageCompletion)(PINRemoteImageManagerResult *result);

/**
 Processor block to post-process a downloaded image. Passed in a PINRemoteImageManagerResult and a pointer to an NSUInteger which can be updated to indicate the cost of processing the image.
 
 @param result PINRemoteImageManagerResult which contains the downloaded image.
 @param cost NSUInteger point which can be modified to indicate the cost of processing the image. This is used when determining which cache objects to evict on memory pressure.
 
 @return return the processed UIImage
 */
typedef UIImage *(^PINRemoteImageManagerImageProcessor)(PINRemoteImageManagerResult *result, NSUInteger *cost);

/**
 PINRemoteImageManager is the main workhorse of PINRemoteImage. It is unnecessary to access directly if you simply
 wish to download images and have them rendered in a UIImageView, UIButton or FLAnimatedImageView.
 
 However, if you wish to download images directly, this class is your guy / gal.
 
 You can use this class to download images, postprocess downloaded images, prefetch images, download images progressively, or download one image in a set of images depending on network performance.
 */

/**
 Completion Handler block which will be forwarded to NSURLSessionTaskDelegate's completion handler
 
 @param disposition One of several constants that describes how the challenge should be handled.
 @param credential The credential that should be used for authentication if disposition is NSURLSessionAuthChallengeUseCredential; otherwise, NULL.
 */
typedef void(^PINRemoteImageManagerAuthenticationChallengeCompletionHandler)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *credential);

/**
 Authentication challenge handler
 
 @param task The task whose request requires authentication.
 @param challenge An object that contains the request for authentication.
 @param aHandler A PINRemoteImageManagerAuthenticationChallengeCompletionHandler, see example for further details.
 */
typedef void(^PINRemoteImageManagerAuthenticationChallenge)(NSURLSessionTask *task, NSURLAuthenticationChallenge *challenge, PINRemoteImageManagerAuthenticationChallengeCompletionHandler aHandler);

@interface PINRemoteImageManager : NSObject

@property (nonatomic, readonly) PINCache *cache;

/**
 Create and return a PINRemoteImageManager created with the specified configuration. If configuration is nil, [NSURLSessionConfiguration defaultConfiguration] is used. You specify a custom configuration if you need to configure timeout values, cookie policies, additional HTTP headers, etc.
 @param configuration The configuration used to create the PINRemoteImageManager.
 @return A PINRemoteImageManager with the specified configuration.
 */
- (instancetype)initWithSessionConfiguration:(NSURLSessionConfiguration *)configuration;

/**
 Get the shared instance of PINRemoteImageManager
 
 @return Shared instance of PINRemoteImageManager
 */
+ (instancetype)sharedImageManager;

/**
 The result of this method is assigned to self.cache in init. If you wish to provide a customized cache to the manager you can subclass PINRemoteImageManager and return a custom PINCache from this method.
 @return An instance of a PINCache object.
 */
- (PINCache *)defaultImageCache;

/**
 Set the Authentication Challenge Block
 @see PINRemoteImageManagerAuthenticationChallenge
 
 @param challengeBlock A PINRemoteImageManagerAuthenticationChallenge block.
 */
- (void)setAuthenticationChallenge:(PINRemoteImageManagerAuthenticationChallenge)aChallenge;

/**
 Set the minimum BPS to download the highest quality image in a set.
 @see downloadImageWithURLs:options:progress:completion:
 
 @param highQualityBPSThreshold bytes per second minimum. Defaults to 500000.
 @param completion Completion to be called once highQualityBPSThreshold has been set.
 */
- (void)setHighQualityBPSThreshold:(float)highQualityBPSThreshold completion:(dispatch_block_t)completion;

/**
 Set the maximum BPS to download the lowest quality image in a set.
 @see downloadImageWithURLs:options:progress:completion:

 @param lowQualityBPSThreshold bytes per second maximum. Defaults to 50000.
 @param completion Completion to be called once lowQualityBPSThreshold has been set.
 */
- (void)setLowQualityBPSThreshold:(float)lowQualityBPSThreshold
                       completion:(dispatch_block_t)completion;

/**
 Set whether high quality images should be downloaded when a low quality image is cached if network connectivity has improved.
 @see downloadImageWithURLs:options:progress:completion:
 
 @param shouldUpgradeLowQualityImages if YES, low quality images will be 'upgraded'.
 @param completion Completion to be called once shouldUpgradeLowQualityImages has been set.
 */
- (void)setShouldUpgradeLowQualityImages:(BOOL)shouldUpgradeLowQualityImages
                              completion:(dispatch_block_t)completion;

/**
 Set the maximum number of concurrent operations (decompressing images, creating gifs, etc).
 
 @param maxNumberOfConcurrentOperations The maximum number of concurrent operations. Defaults to NSOperationQueueDefaultMaxConcurrentOperationCount.
 @param completion Completion to be called once maxNumberOfConcurrentOperations is set.
 */
- (void)setMaxNumberOfConcurrentOperations:(NSInteger)maxNumberOfConcurrentOperations
                                completion:(dispatch_block_t)completion;

/**
 Set the maximum number of concurrent downloads.
 
 @param maxNumberOfConcurrentDownloads The maximum number of concurrent downloads. Defaults to 10.
 @param completion Completion to be called once maxNumberOfConcurrentDownloads is set.
 */
- (void)setMaxNumberOfConcurrentDownloads:(NSInteger)maxNumberOfConcurrentDownloads
                               completion:(dispatch_block_t)completion;

/**
 Set the estimated time remaining to download threshold at which to generate progressive images. Progressive images previews will only be generated if the estimated remaining time on a download is greater than estimatedTimeRemainingThreshold. If estimatedTimeRemainingThreshold is less than zero, this check is skipped.
 
 @param estimatedRemainingTimeThreshold The estimated remaining time threshold used to decide to skip progressive rendering. Defaults to 0.1.
 @param completion Completion to be called once estimatedTimeRemainingTimeThreshold is set.
 */
- (void)setEstimatedRemainingTimeThresholdForProgressiveDownloads:(NSTimeInterval)estimatedRemainingTimeThreshold
                                                       completion:(dispatch_block_t)completion;

/**
 Sets the progress at which progressive images are generated. By default this is @[@0.00, @0.35, @0.65] which generates at most, 3 progressive images. The first progressive image will only be generated when at least one scan has been completed (so you never see half an image).
 
 @param progressThresholds an array of progress thresholds at which to generate progressive images. progress thresholds should range from 0.00 - 1.00. Defaults to @[@0.00, @0.35, @0.65]
 @param completion Completion to be called once progressThresholds is set.
 */
- (void)setProgressThresholds:(NSArray *)progressThresholds
                   completion:(dispatch_block_t)completion;

/**
 Prefetch an image at the given URL.
 
 @param url NSURL where the image to prefetch resides.
 */
- (void)prefetchImageWithURL:(NSURL *)url;

/**
 Prefetch an image at the given URL with given options.
 
 @param url NSURL where the image to prefetch resides.
 @param options PINRemoteImageManagerDownloadOptions options with which to pefetch the image.
 */
- (void)prefetchImageWithURL:(NSURL *)url options:(PINRemoteImageManagerDownloadOptions)options;

/**
 Prefetch images at the given URLs.
 
 @param urls An array of NSURLs where the images to prefetch reside.
 */
- (void)prefetchImagesWithURLs:(NSArray *)urls;

/**
 Prefetch images at the given URLs with given options.
 
 @param urls An array of NSURLs where the images to prefetch reside.
 @param options PINRemoteImageManagerDownloadOptions options with which to pefetch the image.
 */
- (void)prefetchImagesWithURLs:(NSArray *)urls options:(PINRemoteImageManagerDownloadOptions)options;;

/**
 Download or retrieve from cache the image found at the url. All completions are called on an arbitrary callback queue unless called on the main thread and the result is in the memory cache (this is an optimization to allow synchronous results for the UI when an object is cached in memory).
 
 @param url NSURL where the image to download resides.
 @param completion PINRemoteImageManagerImageCompletion block to call when image has been fetched from the cache or downloaded.
 @return An NSUUID which uniquely identifies this request. To be used for canceling requests and verifying that the callback is for the request you expect (see categories for example).
 */
- (NSUUID *)downloadImageWithURL:(NSURL *)url completion:(PINRemoteImageManagerImageCompletion)completion;

/**
 Download or retrieve from cache the image found at the url. All completions are called on an arbitrary callback queue unless called on the main thread and the result is in the memory cache (this is an optimization to allow synchronous results for the UI when an object is cached in memory).
 
 @param url NSURL where the image to download resides.
 @param options PINRemoteImageManagerDownloadOptions options with which to fetch the image.
 @param completion PINRemoteImageManagerImageCompletion block to call when image has been fetched from the cache or downloaded.
 @return An NSUUID which uniquely identifies this request. To be used for canceling requests and verifying that the callback is for the request you expect (see categories for example).
 */
- (NSUUID *)downloadImageWithURL:(NSURL *)url
                         options:(PINRemoteImageManagerDownloadOptions)options
                      completion:(PINRemoteImageManagerImageCompletion)completion;

/**
 Download or retrieve from cache the image found at the url. All completions are called on an arbitrary callback queue unless called on the main thread and the result is in the memory cache (this is an optimization to allow synchronous results for the UI when an object is cached in memory).
 
 @param url NSURL where the image to download resides.
 @param options PINRemoteImageManagerDownloadOptions options with which to fetch the image.
 @param progress PINRemoteImageManagerImageCompletion block which will be called to update progress of the image download.
 @param completion PINRemoteImageManagerImageCompletion block to call when image has been fetched from the cache or downloaded.
 
 @return An NSUUID which uniquely identifies this request. To be used for canceling requests and verifying that the callback is for the request you expect (see categories for example).
 */
- (NSUUID *)downloadImageWithURL:(NSURL *)url
                         options:(PINRemoteImageManagerDownloadOptions)options
                        progress:(PINRemoteImageManagerImageCompletion)progress
                      completion:(PINRemoteImageManagerImageCompletion)completion;

/**
 Download or retrieve from cache the image found at the url and process it before calling completion. All completions are called on an arbitrary callback queue unless called on the main thread and the result is in the memory cache (this is an optimization to allow synchronous results for the UI when an object is cached in memory).
 
 @param url NSURL where the image to download resides.
 @param options PINRemoteImageManagerDownloadOptions options with which to fetch the image.
 @param processorKey NSString key to uniquely identify processor and process. Will be used for caching processed images.
 @param processor PINRemoteImageManagerImageProcessor block which will be called to post-process downloaded image.
 @param completion PINRemoteImageManagerImageCompletion block to call when image has been fetched from the cache or downloaded.
 
 @return An NSUUID which uniquely identifies this request. To be used for canceling requests and verifying that the callback is for the request you expect (see categories for example).
 */
- (NSUUID *)downloadImageWithURL:(NSURL *)url
                         options:(PINRemoteImageManagerDownloadOptions)options
                    processorKey:(NSString *)processorKey
                       processor:(PINRemoteImageManagerImageProcessor)processor
                      completion:(PINRemoteImageManagerImageCompletion)completion;

/**
 Download or retrieve from cache one of the images found at the urls in the passed in array based on current network performance. URLs should be sorted from lowest quality image URL to highest. All completions are called on an arbitrary callback queue unless called on the main thread and the result is in the memory cache (this is an optimization to allow synchronous results for the UI when an object is cached in memory).
 
 Unless setShouldUpgradeLowQualityImages is set to YES, this method checks the cache for all URLs and returns the highest quality version stored. It is possible though unlikely for a cached image to not be returned if it is still being cached while a call is made to this method and if network conditions have changed. See source for more details.
 
 @param urls An array of NSURLs of increasing size.
 @param options PINRemoteImageManagerDownloadOptions options with which to fetch the image.
 @param progress PINRemoteImageManagerImageCompletion block which will be called to update progress of the image download.
 @param completion PINRemoteImageManagerImageCompletion block to call when image has been fetched from the cache or downloaded.
 
 @return An NSUUID which uniquely identifies this request. To be used for canceling requests and verifying that the callback is for the request you expect (see categories for example).
 */
- (NSUUID *)downloadImageWithURLs:(NSArray *)urls
                          options:(PINRemoteImageManagerDownloadOptions)options
                         progress:(PINRemoteImageManagerImageCompletion)progress
                       completion:(PINRemoteImageManagerImageCompletion)completion;

/**
 Returns the cacheKey for a given URL and processorKey. Exposed to be overridden if necessary or to be used with imageFromCacheWithCacheKey
 @see imageFromCacheWithCacheKey:completion:
 
 @param url NSURL to be downloaded
 @param processorKey NSString key to uniquely identify processor and process.
 
 @return returns an NSString which is the key used for caching.
 */
- (NSString *)cacheKeyForURL:(NSURL *)url processorKey:(NSString *)processorKey;

/**
 Directly get an image from the underlying cache.
 @see cacheKeyForURL:processorKey:
 
 @param cacheKey NSString key to look up image in the cache.
 @param completion PINRemoteImageManagerImageCompletion block to call when image has been fetched from the cache.
 */
- (void)imageFromCacheWithCacheKey:(NSString *)cacheKey completion:(PINRemoteImageManagerImageCompletion)completion;

/**
 Cancel a download. Canceling will only cancel the download if all other downloads are also canceled with their associated UUIDs. Canceling *does not* guarantee that your completion will not be called. You can use the UUID provided on the result object verify the completion you want called is being called.
 @see PINRemoteImageCategoryManager
 
 @param UUID NSUUID of the task to cancel.
 */
- (void)cancelTaskWithUUID:(NSUUID *)UUID;

/**
 Set the priority of a download task. Since there is only one task per download, the priority of the download task will always be the last priority this method was called with.
 
 @param priority priority to set on the task.
 @param UUID NSUUID of the task to set the priority on.
 */
- (void)setPriority:(PINRemoteImageManagerPriority)priority ofTaskWithUUID:(NSUUID *)UUID;

@end
