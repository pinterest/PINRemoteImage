//
//  PINRemoteImage.h
//
//  Created by Garrett Moon on 8/17/14.
//
//

#import "PINRemoteImageMacros.h"

#if USE_PINCACHE
  #import "PINCache+PINRemoteImageCaching.h"
#endif

#import "NSData+ImageDetectors.h"
#import "PINAlternateRepresentationProvider.h"
#import "PINCachedAnimatedImage.h"
#import "PINGIFAnimatedImage.h"
#import "PINWebPAnimatedImage.h"
#import "PINAPNGAnimatedImage.h"
#import "PINRemoteImageManager.h"
#import "PINRemoteImageCategoryManager.h"
#import "PINRemoteImageManagerResult.h"
#import "PINRemoteImageCaching.h"
#import "PINProgressiveImage.h"
#import "PINURLSessionManager.h"
#import "PINRequestRetryStrategy.h"
#import "PINAnimatedImageView.h"
#import "PINAnimatedImageView+PINRemoteImage.h"
#import "PINButton+PINRemoteImage.h"
#import "PINImageView+PINRemoteImage.h"

#if __has_include("NSHTTPURLResponse+MaxAge.h")
  #import "NSHTTPURLResponse+MaxAge.h"
  #import "PINDisplayLink.h"
  #import "PINImage+DecodedImage.h"
  #import "PINImage+ScaledImage.h"
  #import "PINImage+WebP.h"
  #import "PINRemoteImageBasicCache.h"
  #import "PINRemoteImageCallbacks.h"
  #import "PINRemoteImageDownloadQueue.h"
  #import "PINRemoteImageDownloadTask.h"
  #import "PINRemoteImageManager+Private.h"
  #import "PINRemoteImageManagerConfiguration.h"
  #import "PINRemoteImageMemoryContainer.h"
  #import "PINRemoteImageProcessorTask.h"
  #import "PINRemoteImageTask+Subclassing.h"
  #import "PINRemoteImageTask.h"
  #import "PINRemoteLock.h"
  #import "PINRemoteWeakProxy.h"
  #import "PINResume.h"
  #import "PINSpeedRecorder.h"
#endif
