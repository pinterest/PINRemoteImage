//
//  PINWebPAnimatedImage.h
//  PINRemoteImage
//
//  Created by Garrett Moon on 9/14/17.
//  Copyright © 2017 Pinterest. All rights reserved.
//

#import <Foundation/Foundation.h>

#if PIN_TARGET_IOS
#import <UIKit/UIKit.h>
#elif PIN_TARGET_MAC
#import <Cocoa/Cocoa.h>
#endif

#import "PINRemoteImageMacros.h"

@interface PINWebPAnimatedImage : NSObject

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithAnimatedImageData:(NSData *)animatedImageData NS_DESIGNATED_INITIALIZER;

@property (nonatomic, readwrite) void (^coverImageReadyCallback)(PINImage *coverImage);

/**
 @abstract Returns whether the supplied data contains a supported animated image format.
 @param data the data to check if contains a supported animated image.
 */
- (BOOL)isDataSupported:(NSData *)data;

/**
 @abstract Return the objects's cover image.
 */
@property (nonatomic, readonly) PINImage *coverImage;
/**
 @abstract Return a boolean to indicate that the cover image is ready.
 */
@property (nonatomic, readonly) BOOL coverImageReady;
/**
 @abstract Return the total duration of the animated image's playback.
 */
@property (nonatomic, readonly) CFTimeInterval totalDuration;
/**
 @abstract Return the interval at which playback should occur. Will be set to a CADisplayLink's frame interval.
 */
@property (nonatomic, readonly) NSUInteger frameInterval;
/**
 @abstract Return the total number of loops the animated image should play or 0 to loop infinitely.
 */
@property (nonatomic, readonly) size_t loopCount;
/**
 @abstract Return the total number of frames in the animated image.
 */
@property (nonatomic, readonly) size_t frameCount;
/**
 @abstract Return YES when playback is ready to occur.
 */
@property (nonatomic, readonly) BOOL playbackReady;
/**
 @abstract Return any error that has occured. Playback will be paused if this returns non-nil.
 */
@property (nonatomic, readonly) NSError *error;
/**
 @abstract Should be called when playback is ready.
 */
@property (nonatomic, readwrite) dispatch_block_t playbackReadyCallback;

/**
 @abstract Return the image at a given index.
 */
- (CGImageRef)imageAtIndex:(NSUInteger)index;
/**
 @abstract Return the duration at a given index.
 */
- (CFTimeInterval)durationAtIndex:(NSUInteger)index;
/**
 @abstract Clear any cached data. Called when playback is paused.
 */
- (void)clearAnimatedImageCache;


@end
