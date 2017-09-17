//
//  PINCachedAnimatedImage.m
//  PINRemoteImage
//
//  Created by Garrett Moon on 9/17/17.
//  Copyright © 2017 Pinterest. All rights reserved.
//

#import "PINCachedAnimatedImage.h"

#import "PINGIFAnimatedImage.h"
#if PIN_WEBP
#import "PINWebPAnimatedImage.h"
#endif

#import "NSData+ImageDetectors.h"

@interface PINCachedAnimatedImage ()
{
    id <PINAnimatedImage> _animatedImage;
    PINImage *_coverImage;
    PINAnimatedImageInfoReady _coverImageReadyCallback;
    dispatch_block_t _playbackReadyCallback;
}
@end

@implementation PINCachedAnimatedImage

- (instancetype)initWithAnimatedImageData:(NSData *)animatedImageData
{
    if ([animatedImageData pin_isGIF]) {
        return [self initWithAnimatedImage:[[PINGIFAnimatedImage alloc] initWithAnimatedImageData:animatedImageData]];
    }
#if PIN_WEBP
    if ([animatedImageData pin_isAnimatedWebP]) {
        return [self initWithAnimatedImage:[[PINWebPAnimatedImage alloc] initWithAnimatedImageData:animatedImageData]];
    }
#endif
    return nil;
}

- (instancetype)initWithAnimatedImage:(id <PINAnimatedImage>)animatedImage
{
    if (self = [super init]) {
        _animatedImage = animatedImage;
        
        // dispatch later so that blocks can be set after init this runloop
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            if (self.coverImageReadyCallback) {
                self.coverImageReadyCallback(self.coverImage);
            }
            if (self.playbackReadyCallback) {
                self.playbackReadyCallback();
            }
        });
    }
    return self;
}

- (PINImage *)coverImage
{
    if (_coverImage == nil) {
#if PIN_TARGET_IOS
        _coverImage = [UIImage imageWithCGImage:[_animatedImage imageAtIndex:0]];
#elif PIN_TARGET_MAC
        _coverImage = [[NSImage alloc] initWithCGImage:[_animatedImage imageAtIndex:0] size:CGSizeMake(self.width, self.height)];
#endif
    }
    return _coverImage;
}

- (BOOL)coverImageReady
{
    return YES;
}

#pragma mark - passthrough

- (CFTimeInterval)totalDuration
{
    return _animatedImage.totalDuration;
}

- (NSUInteger)frameInterval
{
    return _animatedImage.frameInterval;
}

- (size_t)loopCount
{
    return _animatedImage.loopCount;
}

- (size_t)frameCount
{
    return _animatedImage.frameCount;
}

- (NSError *)error
{
    return _animatedImage.error;
}

- (CGImageRef)imageAtIndex:(NSUInteger)index
{
    //for now…
    return [_animatedImage imageAtIndex:index];
}

- (CFTimeInterval)durationAtIndex:(NSUInteger)index
{
    return [_animatedImage durationAtIndex:index];
}

- (BOOL)playbackReady
{
    return YES;
}

- (dispatch_block_t)playbackReadyCallback
{
    return _playbackReadyCallback;
}

- (void)setPlaybackReadyCallback:(dispatch_block_t)playbackReadyCallback
{
    _playbackReadyCallback = playbackReadyCallback;
}

- (PINAnimatedImageInfoReady)coverImageReadyCallback
{
    return _coverImageReadyCallback;
}

- (void)setCoverImageReadyCallback:(PINAnimatedImageInfoReady)coverImageReadyCallback
{
    _coverImageReadyCallback = coverImageReadyCallback;
}

/**
 @abstract Clear any cached data. Called when playback is paused.
 */
- (void)clearAnimatedImageCache
{
    
}

@end
