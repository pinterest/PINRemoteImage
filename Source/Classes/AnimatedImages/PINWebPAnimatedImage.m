//
//  PINWebPAnimatedImage.m
//  PINRemoteImage
//
//  Created by Garrett Moon on 9/14/17.
//  Copyright © 2017 Pinterest. All rights reserved.
//

#if PIN_WEBP

#import "PINWebPAnimatedImage.h"

#import "NSData+ImageDetectors.h"

#import "webp/demux.h"

@interface PINAnimatedWebPFrameInfo : NSObject <NSCopying>

/**
 * Each frame of an animated WebP may cover only a portion of the full image.
 * `frameRect` records what portion of the image this frame covers
 */
@property (nonatomic, readonly) CGRect frameRect;

/**
 * If YES, this frame will be replaced with blank space when the next frame
 * of the animation is rendered.
 */
@property (nonatomic, readonly) BOOL disposeToBackground;

/**
 * Whether transparent portions of this frame should be rendered on top of the
 * previous frame
 */
@property (nonatomic, readonly) BOOL blendWithPreviousFrame;

/**
 * Whether the frame has alpha.
 */
@property (nonatomic, readonly) BOOL hasAlpha;

/**
 * Designated initializer.
 */
- (instancetype)initWithFrameRect:(CGRect)frameRect disposeToBackground:(BOOL)disposeToBackground blendWithPreviousFrame:(BOOL)blendWithPreviousFrame hasAlpha:(BOOL)hasAlpha;

@end

@implementation PINAnimatedWebPFrameInfo

- (instancetype)initWithFrameRect:(CGRect)frameRect disposeToBackground:(BOOL)disposeToBackground blendWithPreviousFrame:(BOOL)blendWithPreviousFrame hasAlpha:(BOOL)hasAlpha
{
  if (self = [super init]) {
    _frameRect = frameRect;
    _disposeToBackground = disposeToBackground;
    _blendWithPreviousFrame = blendWithPreviousFrame;
    _hasAlpha = hasAlpha;
  }

  return self;
}

@synthesize frameRect = _frameRect;

@synthesize disposeToBackground = _disposeToBackground;

@synthesize blendWithPreviousFrame = _blendWithPreviousFrame;

@synthesize hasAlpha = _hasAlpha;


#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone
{
  // Immutable.
  return self;
}

@end

@interface PINWebPAnimatedImage ()
{
    NSData *_animatedImageData;
    WebPData _underlyingData;
    WebPDemuxer *_demux;
    CGImageRef previousFrame;
    uint32_t _width;
    uint32_t _height;
    BOOL _hasAlpha;
    size_t _frameCount;
    size_t _loopCount;
    CFTimeInterval *_durations;
    NSError *_error;
    NSMutableArray<PINAnimatedWebPFrameInfo *> *_frameInfos;
}

@end

static void releaseData(void *info, const void *data, size_t size)
{
    WebPFree((void *)data);
}

@implementation PINWebPAnimatedImage

- (instancetype)initWithAnimatedImageData:(NSData *)animatedImageData
{
    if (self = [super init]) {
        _animatedImageData = animatedImageData;
        _underlyingData.bytes = [animatedImageData bytes];
        _underlyingData.size = [animatedImageData length];
        _demux = WebPDemux(&_underlyingData);
        
        if (_demux != NULL) {
            _width = WebPDemuxGetI(_demux, WEBP_FF_CANVAS_WIDTH);
            _height = WebPDemuxGetI(_demux, WEBP_FF_CANVAS_HEIGHT);
            _frameCount = WebPDemuxGetI(_demux, WEBP_FF_FRAME_COUNT);
            _loopCount = WebPDemuxGetI(_demux, WEBP_FF_LOOP_COUNT);
            uint32_t flags = WebPDemuxGetI(_demux, WEBP_FF_FORMAT_FLAGS);
            _hasAlpha = flags & ALPHA_FLAG;
            _durations = malloc(sizeof(CFTimeInterval) * _frameCount);
            _frameInfos = [[NSMutableArray alloc] init];

            // Iterate over the frames to gather duration
            WebPIterator iter;
            if (WebPDemuxGetFrame(_demux, 1, &iter)) {
                do {
                    CGRect frameRect = CGRectMake(iter.x_offset, iter.y_offset, iter.width, iter.height);
                    // Ensure the frame rect doesn't exceed the image size. If it does, reduce the width/height appropriately
                    if (CGRectGetMaxX(frameRect) > _width) {
                      frameRect.size.width = _width - iter.x_offset;
                    }
                    if (CGRectGetMaxY(frameRect) > _height) {
                      frameRect.size.height = _height - iter.y_offset;
                    }
                    BOOL disposeToBackground = (iter.dispose_method == WEBP_MUX_DISPOSE_BACKGROUND);
                    BOOL blendWithPreviousFrame = (iter.blend_method == WEBP_MUX_BLEND);
                    BOOL hasAlpha = iter.has_alpha;
                    PINAnimatedWebPFrameInfo *frameInfo =
                    [[PINAnimatedWebPFrameInfo alloc] initWithFrameRect:frameRect
                                                    disposeToBackground:disposeToBackground
                                                 blendWithPreviousFrame:blendWithPreviousFrame
                                                               hasAlpha:hasAlpha];
                    [_frameInfos addObject:frameInfo];

                    CFTimeInterval duration = iter.duration / 1000.0;
                    static dispatch_once_t onceToken;
                    static CFTimeInterval maximumDuration;
                    dispatch_once(&onceToken, ^{
                        maximumDuration = 1.0 / [PINAnimatedImage maximumFramesPerSecond];
                    });
                    if (duration < maximumDuration) {
                        duration = kPINAnimatedImageDefaultDuration;
                    }
                    _durations[iter.frame_num - 1] = duration;
                } while (WebPDemuxNextFrame(&iter));
                WebPDemuxReleaseIterator(&iter);
            }
        }
    }
    return self;
}

- (void)dealloc
{
    if (_demux) {
        WebPDemuxDelete(_demux);
    }
    if (_durations) {
        free(_durations);
    }
}

- (NSData *)data
{
    return _animatedImageData;
}

- (size_t)frameCount
{
    return _frameCount;
}

- (size_t)loopCount
{
    return _loopCount;
}

- (uint32_t)width
{
    return _width;
}

- (uint32_t)height
{
    return _height;
}

- (uint32_t)bytesPerFrame
{
    return _width * _height * (_hasAlpha ? 4 : 3);
}

- (NSError *)error
{
    return _error;
}

- (CFTimeInterval)durationAtIndex:(NSUInteger)index
{
    return _durations[index];
}

- (CGImageRef)canvasWithPreviousFrame:(CGImageRef)previousFrame image:(CGImageRef)image atRect:(CGRect)rect atIndex:(NSUInteger)index
{
    PINAnimatedWebPFrameInfo *previousFrameInfo = index > 0 ? _frameInfos[index - 1] : nil;
    PINAnimatedWebPFrameInfo *frameInfo = _frameInfos[index];
    CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(NULL,
                                                 _width,
                                                 _height,
                                                 8,
                                                 0,
                                                 colorSpaceRef,
                                                 _hasAlpha ? kCGImageAlphaPremultipliedFirst : kCGImageAlphaNone);
    
    if (previousFrame) {
        CGContextDrawImage(context, CGRectMake(0, 0, _width, _height), previousFrame);
    }

    if (previousFrameInfo.disposeToBackground) {
      // Erase part of the previous image covered by the previous frame if it specified that it
      // should be disposed.
      CGContextClearRect(context, [self drawRectFromIteraterRect:previousFrameInfo.frameRect]);
    }

    CGRect drawRect = [self drawRectFromIteraterRect:rect];
    // If the new frame specifies that it should not be blended with the previous image,
    // clear the part of the image the new frame covers.
    if (!frameInfo.blendWithPreviousFrame) {
      CGContextClearRect(context, drawRect);
    }

    if (image) {
        CGContextDrawImage(context, drawRect, image);
    }
    
    CGImageRef canvas = CGBitmapContextCreateImage(context);
    if (canvas) {
        CFAutorelease(canvas);
    }
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpaceRef);
    
    return canvas;
}

- (CGRect)drawRectFromIteraterRect:(CGRect)rect {
    return CGRectMake(rect.origin.x, _height - rect.size.height - rect.origin.y, rect.size.width, rect.size.height);
}

- (CGImageRef)rawImageWithIterator:(WebPIterator)iterator
{
    CGImageRef imageRef = NULL;
    uint8_t *data = NULL;
    int pixelLength = 0;
    
    if (iterator.has_alpha) {
        data = WebPDecodeRGBA(iterator.fragment.bytes, iterator.fragment.size, NULL, NULL);
        pixelLength = 4;
    } else {
        data = WebPDecodeRGB(iterator.fragment.bytes, iterator.fragment.size, NULL, NULL);
        pixelLength = 3;
    }
    
    if (data) {
        CGDataProviderRef provider = CGDataProviderCreateWithData(NULL, data, iterator.width * iterator.height * pixelLength, releaseData);
        
        CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
        CGBitmapInfo bitmapInfo = kCGBitmapByteOrderDefault;
        
        if (iterator.has_alpha) {
            bitmapInfo |= kCGImageAlphaLast;
        } else {
            bitmapInfo |= kCGImageAlphaNone;
        }
        
        CGColorRenderingIntent renderingIntent = kCGRenderingIntentDefault;
        imageRef = CGImageCreate(iterator.width,
                                 iterator.height,
                                 8,
                                 8 * pixelLength,
                                 pixelLength * iterator.width,
                                 colorSpaceRef,
                                 bitmapInfo,
                                 provider,
                                 NULL,
                                 NO,
                                 renderingIntent);
        
        CGColorSpaceRelease(colorSpaceRef);
        CGDataProviderRelease(provider);
    }
    
    if (imageRef) {
        CFAutorelease(imageRef);
    }
    
    return imageRef;
}

- (CGImageRef)imageAtIndex:(NSUInteger)index cacheProvider:(nullable id<PINCachedAnimatedFrameProvider>)cacheProvider
{
    PINLog(@"Drawing webp image at index: %lu", (unsigned long)index);
    // This all *appears* to be threadsafe as I believe demux is immutable…
    WebPIterator iterator, previousIterator;
    
    if (index > 0) {
        if (WebPDemuxGetFrame(_demux, (int)index, &previousIterator) == NO) {
            return nil;
        }
    }
    if (WebPDemuxGetFrame(_demux, (int)index + 1, &iterator) == NO) {
        return nil;
    }
    
    BOOL isKeyFrame = [self isKeyFrame:&iterator previousIterator:(index > 0) ? &previousIterator : nil];
    
    CGImageRef imageRef = [self rawImageWithIterator:iterator];
    CGImageRef canvas = NULL;
    
    if (imageRef) {
        if (isKeyFrame) {
            // If the current frame is a keyframe, we can just copy it into a blank
            // canvas.
            if (iterator.x_offset == 0 && iterator.y_offset == 0 && iterator.width == _width && iterator.height == _height) {
                // Output will be the same size as the canvas, just return it directly.
                canvas = imageRef;
            } else {
                canvas = [self canvasWithPreviousFrame:nil image:imageRef atRect:CGRectMake(iterator.x_offset, iterator.y_offset, iterator.width, iterator.height) atIndex:index];
            }
        } else {
            // If we have a cached image provider, try to get the last frame from them
            CGImageRef previousFrame = [cacheProvider cachedFrameImageAtIndex:index - 1];
            if (previousFrame) {
                if (![self frameRequiresBlendingWithPreviousFrame:index]) {
                  previousFrame = imageRef;
                }
                canvas = [self canvasWithPreviousFrame:previousFrame image:imageRef atRect:CGRectMake(iterator.x_offset, iterator.y_offset, iterator.width, iterator.height) atIndex:index];
            } else if (index > 0) {
                // Sadly, we need to draw *all* the frames from the previous key frame previousIterator to the current one :(
                CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
                CGContextRef context = CGBitmapContextCreate(NULL,
                                                             _width,
                                                             _height,
                                                             8,
                                                             0,
                                                             colorSpaceRef,
                                                             _hasAlpha ? kCGImageAlphaPremultipliedFirst : kCGImageAlphaNone);
                
                while (previousIterator.frame_num < iterator.frame_num) {
                    CGImageRef previousFrame = [self rawImageWithIterator:previousIterator];
                    if (previousFrame) {
                        CGContextDrawImage(context, CGRectMake(previousIterator.x_offset, _height - previousIterator.height - previousIterator.y_offset, previousIterator.width, iterator.height), previousFrame);
                        WebPDemuxNextFrame(&previousIterator);
                    }
                }
                
                canvas = CGBitmapContextCreateImage(context);
                if (canvas) {
                    CFAutorelease(canvas);
                }
                CGContextRelease(context);
                CGColorSpaceRelease(colorSpaceRef);
            }
        }
    }
    
    WebPDemuxReleaseIterator(&iterator);
    if (index > 0) {
        WebPDemuxReleaseIterator(&previousIterator);
    }
    
    return canvas;
}

- (BOOL)frameRequiresBlendingWithPreviousFrame:(NSUInteger)index
{
    if (index == 0) {
      return NO;
    }

    CGRect imageRect = CGRectMake(0, 0, _width, _height);
    PINAnimatedWebPFrameInfo *frameInfo = _frameInfos[index];
    BOOL frameCoversImage = CGRectContainsRect(frameInfo.frameRect, imageRect);
    // If this frame covers the full image, and doesn't require blending, or doesn't have any alpha,
    // it does not require blending with the previous frame.
    if (frameCoversImage && (!frameInfo.blendWithPreviousFrame || !frameInfo.hasAlpha)) {
      return NO;
    }

    NSUInteger previousIndex = index - 1;
    PINAnimatedWebPFrameInfo *previousFrameInfo = _frameInfos[previousIndex];
    if (previousFrameInfo.disposeToBackground) {
      // If the previous frame covers the full image, and will be cleared, we don't need to blend
      if (CGRectContainsRect(previousFrameInfo.frameRect, imageRect)) {
        return NO;
      }
      // If the previous frame will be cleared, and it doesn't require blending with previous frames, we don't need to blend
      if ([self frameRequiresBlendingWithPreviousFrame:previousIndex] == NO) {
        return NO;
      }
      return YES;
    } else {
      return YES;
    }
}

// Checks to see if the iterator is a 'key frame' without taking previous frames into
// account.
- (BOOL)helperIsKeyFrame:(WebPIterator *)iterator
{
    if (iterator->frame_num == 1) {
        //The first frame is always a key frame
        return YES;
    } else if ((iterator->has_alpha == NO || iterator->blend_method == WEBP_MUX_NO_BLEND) && iterator->width == _width && iterator->height == _height) {
        //If the current frame has no alpha, or we're instructed not to blend, just make sure this fills the canvas.
        return YES;
    }
    return NO;
}

// Checks if the iterator is at a 'key frame' and rewinds previousIterator back to the last
// key frame if it's not. If this frame *is* a keyframe, the previousIterator's position is undefined.
// This takes previous frames into account to determine if the current frame is key.
- (BOOL)isKeyFrame:(WebPIterator *)iterator previousIterator:(WebPIterator *)previousIterator
{
    if ([self helperIsKeyFrame:iterator]) {
        // Check if we're a key frame regardless of previous frame.
        return YES;
    }
    
    if (previousIterator == nil) {
        return NO;
    }
    
    BOOL previousFrameMadeThisKeyFrame = previousIterator->dispose_method == WEBP_MUX_DISPOSE_BACKGROUND;
    BOOL foundKeyframe = NO;
    while (foundKeyframe == NO) {
        if ([self helperIsKeyFrame:previousIterator] ||
            (previousIterator->dispose_method == WEBP_MUX_DISPOSE_BACKGROUND && previousIterator->width == _width && previousIterator->height == _height)) {
            foundKeyframe = YES;
        } else {
            // we need to rewind previous back to see if it was a keyframe
            WebPDemuxPrevFrame(previousIterator);
            if (previousIterator->dispose_method == WEBP_MUX_DISPOSE_BACKGROUND) {
                // need to check previous frame
                continue;
            } else {
                previousFrameMadeThisKeyFrame = NO;
                continue;
            }
        }
    }
        
    return previousFrameMadeThisKeyFrame;
}

@end

#endif
