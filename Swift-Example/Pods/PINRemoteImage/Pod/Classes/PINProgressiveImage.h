//
//  PINProgressiveImage.h
//  Pods
//
//  Created by Garrett Moon on 2/9/15.
//
//

#import <UIKit/UIKit.h>

@interface PINProgressiveImage : NSObject

@property (atomic, copy) NSArray *progressThresholds;
@property (atomic, assign) CFTimeInterval estimatedRemainingTimeThreshold;
@property (atomic, assign) CFTimeInterval startTime;

- (void)updateProgressiveImageWithData:(NSData *)data expectedNumberOfBytes:(int64_t)expectedNumberOfBytes;

//Returns the latest image based on thresholds, returns nil if no new image is generated
- (UIImage *)currentImage;

- (NSData *)data;

@end
