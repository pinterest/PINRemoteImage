//
//  PINRemoteImageManagerResult.h
//  Pods
//
//  Created by Garrett Moon on 3/9/15.
//
//

#import <UIKit/UIKit.h>

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

@property (nonatomic, readonly, strong, nullable) UIImage *image;
@property (nonatomic, readonly, strong, nullable) FLAnimatedImage *animatedImage;
@property (nonatomic, readonly, assign) NSTimeInterval requestDuration;
@property (nonatomic, readonly, strong, nullable) NSError *error;
@property (nonatomic, readonly, assign) PINRemoteImageResultType resultType;
@property (nonatomic, readonly, strong, nullable) NSUUID *UUID;

+ (nonnull instancetype)imageResultWithImage:(nullable UIImage *)image
                               animatedImage:(nullable FLAnimatedImage *)animatedImage
                               requestLength:(NSTimeInterval)requestLength
                                       error:(nullable NSError *)error
                                  resultType:(PINRemoteImageResultType)resultType
                                        UUID:(nullable NSUUID *)uuid;

@end
