//
//  PINProgressiveImage.h
//  Pods
//
//  Created by Garrett Moon on 2/9/15.
//
//

#import <Foundation/Foundation.h>

#if PIN_TARGET_IOS
#import <UIKit/UIKit.h>
#elif PIN_TARGET_MAC
#import <Cocoa/Cocoa.h>
#endif

#import "PINRemoteImageMacros.h"

@class PINRemoteImageDownloadTask;

/** An object which store the data of a downloading image and vends progressive scans **/
@interface PINProgressiveImage : NSObject

@property (atomic, copy, nonnull) NSArray *progressThresholds;
@property (atomic, assign) CFTimeInterval estimatedRemainingTimeThreshold;
@property (nonatomic, strong, readonly, nonnull) NSURLSessionDataTask * dataTask;
@property (nonatomic, readonly) float bytesPerSecond;
@property (nonatomic, readonly) CFTimeInterval estimatedRemainingTime;

- (nonnull instancetype)init NS_UNAVAILABLE;
- (nonnull instancetype)initWithDataTask:(nonnull NSURLSessionDataTask *)dataTask;

- (void)updateProgressiveImageWithData:(nonnull NSData *)data expectedNumberOfBytes:(int64_t)expectedNumberOfBytes isResume:(BOOL)isResume;

/**
 Returns the latest image based on thresholds, returns nil if no new image is generated.
 
 @param blurred A boolean to indicate if the image should be blurred.
 @param maxProgressiveRenderSize The maximum dimensions at which to apply a blur. If an image exceeds either the height.
 or width of this dimension, the image will *not* be blurred regardless of the blurred parameter.
 @param renderedImageQuality Value between 0 and 1. Computed by dividing the received number of bytes by the expected number of bytes.
 @return PINImage A progressive scan of the image or nil if a new one has not been generated.
 */
- (nullable PINImage *)currentImageBlurred:(BOOL)blurred maxProgressiveRenderSize:(CGSize)maxProgressiveRenderSize renderedImageQuality:(nonnull out CGFloat *)renderedImageQuality;

/**
 Returns the current data for the image.
 
 @return NSData The current data for the image.
 */
- (nullable NSData *)data;

/**
 Returns bytes per second adjusted by subtracting subtraction from the task length before calculation.
 Useful when you want something like bytesPerSecond discounting the time to first byte.
 
 @param subtraction An amount to be subtracted from task length before calculation.
 @return float The adjusted bytes per second.
 */
- (float)adjustedBytesPerSecond:(CFTimeInterval)subtraction;

@end
