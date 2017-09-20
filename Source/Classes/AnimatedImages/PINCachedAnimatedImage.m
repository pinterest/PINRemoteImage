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

#import <PINOperation/PINOperationQueue.h>
#import "NSData+ImageDetectors.h"

static const NSUInteger kFramesToRenderForLargeFrames = 4;

@interface PINCachedAnimatedImage ()
{
    // Since _animatedImage is set on init it is thread-safe
    id <PINAnimatedImage> _animatedImage;
    
    PINImage *_coverImage;
    PINAnimatedImageInfoReady _coverImageReadyCallback;
    dispatch_block_t _playbackReadyCallback;
    NSMutableDictionary *_frameCache;
    NSInteger _playbackReady; // Number of frames to cache until playback is ready
    PINOperationQueue *_cachingQueue;
    
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
        _playbackReady = 0;
        _playhead = 0;
        _notifyOnReady = YES;
        _cachedOrCachingFrames = [[NSMutableIndexSet alloc] init];
        _lock = [[PINRemoteLock alloc] initWithName:@"PINCachedAnimatedImage Lock"];
        
        _cachingQueue = [[PINOperationQueue alloc] initWithMaxConcurrentOperations:kFramesToRenderForLargeFrames];
        
        // dispatch later so that blocks can be set after init this runloop
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self imageAtIndex:0];
            if (self.coverImageReadyCallback) {
                self.coverImageReadyCallback(self.coverImage);
            }
        });
    }
    return self;
}

- (PINImage *)coverImage
{
    __block PINImage *coverImage = nil;
    [_lock lockWithBlock:^{
        if (_coverImage == nil) {
#if PIN_TARGET_IOS
            _coverImage = [UIImage imageWithCGImage:[_animatedImage imageAtIndex:0]];
#elif PIN_TARGET_MAC
            _coverImage = [[NSImage alloc] initWithCGImage:[_animatedImage imageAtIndex:0] size:CGSizeMake(self.width, self.height)];
#endif
        }
        coverImage = _coverImage;
    }];
    return coverImage;
}

- (BOOL)coverImageReady
{
    // The cover image is always 'ready'
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
     
        // Retain and autorelease while we have the lock, another thread could remove it from the cache
        // and allow it to be released.
        if (imageRef) {
            CGImageRetain(imageRef);
            CFAutorelease(imageRef);
        }
        
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
    //TODO look into silencing retain cycle warning :/
    PINWeakify(self);
    [_cachingQueue addOperation:^{
        PINStrongify(self);
        // Kick off, in order, caching frames which need to be cached
        __block NSRange endKeepRange;
        __block NSRange beginningKeepRange;
        
        NSUInteger framesToCache = [self framesToCache];
        
        [self->_lock lockWithBlock:^{
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
            
            NSMutableIndexSet *removedFrames = [[NSMutableIndexSet alloc] init];
            PINLog(@"Checking if frames need removing: %lu", _cachedOrCachingFrames.count);
            [self->_cachedOrCachingFrames enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop) {
                if (NSLocationInRange(idx, endKeepRange) == NO &&
                    (beginningKeepRange.location == NSNotFound || NSLocationInRange(idx, beginningKeepRange))) {
                    [removedFrames addIndex:idx];
                    [self->_frameCache removeObjectForKey:@(idx)];
                    PINLog(@"Removing: %lu", (unsigned long)idx);
                }
            }];
            [self->_cachedOrCachingFrames removeIndexes:removedFrames];
        }];
    }];
}

- (void)l_cacheFrame:(NSUInteger)frameIndex
{
    if ([_cachedOrCachingFrames containsIndex:frameIndex] == NO) {
        PINLog(@"Requesting: %lu", (unsigned long)frameIndex);
        [_cachedOrCachingFrames addIndex:frameIndex];
        _playbackReady++;
        
        //TODO instead of weakify / strongify, silence warning, we know what we're doing
        PINWeakify(self);
        [_cachingQueue addOperation:^{
            PINStrongify(self);
            CGImageRef imageRef = [self->_animatedImage imageAtIndex:frameIndex];
            PINLog(@"Generating: %lu", (unsigned long)frameIndex);

            __block dispatch_block_t notify = nil;
            [self->_lock lockWithBlock:^{
                [self->_frameCache setObject:(__bridge id _Nonnull)(imageRef) forKey:@(frameIndex)];
                self->_playbackReady--;
                NSAssert(self->_playbackReady >= 0, @"playback ready is less than zero, something is wrong :(");
                
                PINLog(@"Frames left: %ld", (long)_playbackReady);
                
                if (self->_playbackReady == 0 && self->_notifyOnReady) {
                    self->_notifyOnReady = NO;
                    if (self->_playbackReadyCallback) {
                        notify = self->_playbackReadyCallback;
                    }
                }
            }];
            
            if (notify) {
                notify();
            }
        }];
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
        return kFramesToRenderForLargeFrames;
    } else {
        // Oooph, lets just try to get ahead of things by one.
        return 2;
    }
}

- (CFTimeInterval)durationAtIndex:(NSUInteger)index
{
    return [_animatedImage durationAtIndex:index];
}

- (BOOL)playbackReady
{
    __block BOOL playbackReady = NO;
    [_lock lockWithBlock:^{
        playbackReady = _playbackReady == 0;
    }];
    return playbackReady;
}

- (dispatch_block_t)playbackReadyCallback
{
    __block dispatch_block_t playbackReadyCallback = nil;
    [_lock lockWithBlock:^{
        playbackReadyCallback = _playbackReadyCallback;
    }];
    return playbackReadyCallback;
}

- (void)setPlaybackReadyCallback:(dispatch_block_t)playbackReadyCallback
{
    [_lock lockWithBlock:^{
        _playbackReadyCallback = playbackReadyCallback;
    }];
}

- (PINAnimatedImageInfoReady)coverImageReadyCallback
{
    __block PINAnimatedImageInfoReady coverImageReadyCallback;
    [_lock lockWithBlock:^{
        coverImageReadyCallback = _coverImageReadyCallback;
    }];
    return coverImageReadyCallback;
}

- (void)setCoverImageReadyCallback:(PINAnimatedImageInfoReady)coverImageReadyCallback
{
    [_lock lockWithBlock:^{
        _coverImageReadyCallback = coverImageReadyCallback;
    }];
}

/**
 @abstract Clear any cached data. Called when playback is paused.
 */
- (void)clearAnimatedImageCache
{
    [_lock lockWithBlock:^{
        [_cachedOrCachingFrames enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop) {
            [_frameCache removeObjectForKey:@(idx)];
        }];
        [_cachedOrCachingFrames removeAllIndexes];
    }];
}

@end
