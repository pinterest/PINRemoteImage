//
//  PINCachedAnimatedImage.m
//  PINRemoteImage
//
//  Created by Garrett Moon on 9/17/17.
//  Copyright © 2017 Pinterest. All rights reserved.
//

#import "PINCachedAnimatedImage.h"

#import "PINRemoteLock.h"
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
    NSMutableDictionary *_frameCache;
    NSInteger _playbackReady; // Number of frames to cache until playback is ready
    dispatch_queue_t _cachingQueue;
    
    NSUInteger _playhead;
    BOOL _notifyOnReady;
    NSMutableIndexSet *_cachedOrCachingFrames;
    PINRemoteLock *_lock;
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
        _frameCache = [[NSMutableDictionary alloc] init];
        _playbackReady = -1;
        _playhead = 0;
        _notifyOnReady = YES;
        _cachedOrCachingFrames = [[NSMutableIndexSet alloc] init];
        _lock = [[PINRemoteLock alloc] initWithName:@"PINCachedAnimatedImage Lock"];
        //TODO consider using a PINOperationQueue
        _cachingQueue = dispatch_queue_create("PINCachedAnimatedImage Caching Queue", DISPATCH_QUEUE_CONCURRENT);
        
        // dispatch later so that blocks can be set after init this runloop
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            _playbackReady = 0;
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
    __block CGImageRef imageRef;
    [_lock lockWithBlock:^{
        imageRef = (__bridge CGImageRef)[_frameCache objectForKey:@(index)];
        _playhead = index;
        if (imageRef == NULL) {
            PINLog(@"cache miss, aww.");
            _notifyOnReady = YES;
        }
    }];
    
    [self updateCache];

    return imageRef;
}

- (void)updateCache
{
    dispatch_async(_cachingQueue, ^{
        // Kick off, in order, caching frames which need to be cached
        __block NSRange endKeepRange;
        __block NSRange beginningKeepRange;
        
        NSUInteger framesToCache = [self framesToCache];
        
        [_lock lockWithBlock:^{
            // find the range of frames we want to keep
            endKeepRange = NSMakeRange(_playhead, framesToCache);
            beginningKeepRange = NSMakeRange(NSNotFound, 0);
            if (NSMaxRange(endKeepRange) > _animatedImage.frameCount) {
                beginningKeepRange = NSMakeRange(0, NSMaxRange(endKeepRange) - _animatedImage.frameCount);
                endKeepRange.length = _animatedImage.frameCount - _playhead;
            }
            
            for (NSUInteger idx = endKeepRange.location; idx < NSMaxRange(endKeepRange); idx++) {
                if ([_cachedOrCachingFrames containsIndex:idx] == NO) {
                    [self l_cacheFrame:idx];
                }
            }
            
            if (beginningKeepRange.location != NSNotFound) {
                for (NSUInteger idx = beginningKeepRange.location; idx < NSMaxRange(beginningKeepRange); idx++) {
                    if ([_cachedOrCachingFrames containsIndex:idx] == NO) {
                        [self l_cacheFrame:idx];
                    }
                }
            }
        }];
        
        NSMutableIndexSet *removedFrames = [[NSMutableIndexSet alloc] init];
        PINLog(@"Checking if frames need removing: %lu", _cachedOrCachingFrames.count);
        [_cachedOrCachingFrames enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop) {
            if (NSLocationInRange(idx, endKeepRange) == NO &&
                (beginningKeepRange.location == NSNotFound || NSLocationInRange(idx, beginningKeepRange))) {
                [removedFrames addIndex:idx];
                [_frameCache removeObjectForKey:@(idx)];
                PINLog(@"Removing: %lu", (unsigned long)idx);
            }
        }];
        [_cachedOrCachingFrames removeIndexes:removedFrames];
    });
}

- (void)l_cacheFrame:(NSUInteger)frameIndex
{
    if ([_cachedOrCachingFrames containsIndex:frameIndex] == NO) {
        PINLog(@"Requesting: %lu", (unsigned long)frameIndex);
        [_cachedOrCachingFrames addIndex:frameIndex];
        _playbackReady++;
        dispatch_async(_cachingQueue, ^{
            CGImageRef imageRef = [_animatedImage imageAtIndex:frameIndex];
            PINLog(@"Generating: %lu", (unsigned long)frameIndex);

            __block dispatch_block_t notify = nil;
            [_lock lockWithBlock:^{
                [_frameCache setObject:(__bridge id _Nonnull)(imageRef) forKey:@(frameIndex)];
                _playbackReady--;
                NSAssert(_playbackReady >= 0, @"playback ready is less than zero, something is wrong :(");
                
                PINLog(@"Frames left: %ld", (long)_playbackReady);
                
                if (_playbackReady == 0 && _notifyOnReady) {
                    _notifyOnReady = NO;
                    if (_playbackReadyCallback) {
                        notify = _playbackReadyCallback;
                    }
                }
            }];
            
            if (notify) {
                notify();
            }
        });
    }
}

// Returns the number of frames that should be cached
- (NSUInteger)framesToCache
{
    NSUInteger totalBytes = [NSProcessInfo processInfo].physicalMemory;
    
    // TODO See if the image actually has alpha and take that into account? Delegate to the
    // image to return frame size?
    NSUInteger frameCost = _animatedImage.height * _animatedImage.width * 4;
    if (frameCost * _animatedImage.frameCount < totalBytes / 250) {
        // If the total number of bytes takes up less than a 250th of total memory, lets just cache 'em all.
        return _animatedImage.frameCount;
    } else if (frameCost < totalBytes / 1000 ) {
        // If the cost of a frame is less than 1000th of physical memory, cache 4 frames to smooth animation.
        return 4;
    } else {
        // Oooph, lets just try to get ahead of things by one.
        return 1;
    }
}

- (CFTimeInterval)durationAtIndex:(NSUInteger)index
{
    return [_animatedImage durationAtIndex:index];
}

- (BOOL)playbackReady
{
    return _playbackReady == 0;
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
