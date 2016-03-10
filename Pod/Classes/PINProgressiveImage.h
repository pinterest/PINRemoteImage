//
//  PINProgressiveImage.h
//  Pods
//
//  Created by Garrett Moon on 2/9/15.
//
//

#if TARGET_OS_IPHONE || TARGET_OS_TV
#import <UIKit/UIKit.h>
#elif TARGET_OS_MAC
#import <Cocoa/Cocoa.h>
#endif

#import "PINRemoteImageMacros.h"

@interface PINProgressiveImage : NSObject

@property (atomic, copy, nonnull) NSArray *progressThresholds;
@property (atomic, assign) CFTimeInterval estimatedRemainingTimeThreshold;
@property (atomic, assign) CFTimeInterval startTime;

- (void)updateProgressiveImageWithData:(nonnull NSData *)data expectedNumberOfBytes:(int64_t)expectedNumberOfBytes;

/// Returns the latest image based on thresholds, returns nil if no new image is generated
- (nullable PINImage *)currentImageBlurred:(BOOL)blurred maxProgressiveRenderSize:(CGSize)maxBlurSize;

- (nullable NSData *)data;

@end
