//
//  PINRemoteImageManagerResult.h
//  Pods
//
//  Created by Garrett Moon on 3/9/15.
//
//

#ifdef __IPHONE_OS_VERSION_MIN_REQUIRED
#import <UIKit/UIKit.h>
#else
#import <Cocoa/Cocoa.h>
#endif

#import "PINRemoteImageMacros.h"
#if USE_FLANIMATED_IMAGE
#import <FLAnimatedImage/FLAnimatedImage.h>
#endif

/** How the image was fetched. */
typedef NS_ENUM(NSUInteger, PINRemoteImageResultType) {
    /** Returned if no image is returned */
    PINRemoteImageResultTypeNone = 0,
    /** Image was fetched from the memory cache */
    PINRemoteImageResultTypeMemoryCache,
    /** Image was fetched from the disk cache */
    PINRemoteImageResultTypeCache,
    /** Image was downloaded */
    PINRemoteImageResultTypeDownload,
    /** Image is progress */
    PINRemoteImageResultTypeProgress,
};

@interface PINRemoteImageManagerResult : NSObject

@property (nonatomic, readonly, strong) PINImage *image;
@property (nonatomic, readonly, strong) FLAnimatedImage *animatedImage;
@property (nonatomic, readonly, assign) NSTimeInterval requestDuration;
@property (nonatomic, readonly, strong) NSError *error;
@property (nonatomic, readonly, assign) PINRemoteImageResultType resultType;
@property (nonatomic, readonly, strong) NSUUID *UUID;

+ (instancetype)imageResultWithImage:(PINImage *)image
                       animatedImage:(FLAnimatedImage *)animatedImage
                       requestLength:(NSTimeInterval)requestLength
                               error:(NSError *)error
                          resultType:(PINRemoteImageResultType)resultType
                                UUID:(NSUUID *)uuid;

@end
