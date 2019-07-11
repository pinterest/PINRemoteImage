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
    CGColorRef _backgroundColor;
    CFTimeInterval *_durations;
    NSError *_error;
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
          
            uint32_t backgroundColorInt = WebPDemuxGetI(_demux, WEBP_FF_BACKGROUND_COLOR);
            CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
            CGFloat components[4];
            components[0] = (CGFloat)(((backgroundColorInt & 0xFF000000) >> 24)/255.0);
            components[1] = (CGFloat)(((backgroundColorInt & 0x00FF0000) >> 16)/255.0);
            components[2] = (CGFloat)(((backgroundColorInt & 0x0000FF00) >> 8)/255.0);
            components[3] = (CGFloat)((backgroundColorInt & 0x000000FF)/255.0);
            _backgroundColor = CGColorCreate(rgbColorSpace, components);
            CGColorSpaceRelease(rgbColorSpace);
            
            // Iterate over the frames to gather duration
            WebPIterator iter;
            if (WebPDemuxGetFrame(_demux, 1, &iter)) {
                do {
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
        } else {
            return nil;
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
    if (_backgroundColor) {
        CGColorRelease(_backgroundColor);
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

- (CGImageRef)canvasWithPreviousFrame:(CGImageRef)previousFrame
                    previousFrameRect:(CGRect)previousFrameRect
                   clearPreviousFrame:(BOOL)clearPreviousFrame
                      backgroundColor:(CGColorRef)backgroundColor
                                image:(CGImageRef)image
                    clearCurrentFrame:(BOOL)clearCurrentFrame
                               atRect:(CGRect)rect
{
    CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(NULL,
                                                 _width,
                                                 _height,
                                                 8,
                                                 0,
                                                 colorSpaceRef,
                                                 _hasAlpha ? kCGImageAlphaPremultipliedFirst : kCGImageAlphaNone);
    if (backgroundColor) {
        CGContextSetFillColorWithColor(context, backgroundColor);
    }
    
    if (previousFrame) {
        CGContextDrawImage(context, CGRectMake(0, 0, _width, _height), previousFrame);
        if (clearPreviousFrame) {
            CGContextFillRect(context, previousFrameRect);
        }
    }
    
    if (image) {
        CGRect currentRect = CGRectMake(rect.origin.x, _height - rect.size.height - rect.origin.y, rect.size.width, rect.size.height);
        if (clearCurrentFrame) {
            CGContextFillRect(context, currentRect);
        }
        CGContextDrawImage(context, currentRect, image);
    }
    
    CGImageRef canvas = CGBitmapContextCreateImage(context);
    if (canvas) {
        CFAutorelease(canvas);
    }
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpaceRef);
    
    return canvas;
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
                canvas = [self canvasWithPreviousFrame:nil
                                     previousFrameRect:CGRectZero
                                    clearPreviousFrame:NO
                                       backgroundColor:_backgroundColor
                                                 image:imageRef
                                     clearCurrentFrame:iterator.blend_method == WEBP_MUX_NO_BLEND
                                                atRect:CGRectMake(iterator.x_offset, iterator.y_offset, iterator.width, iterator.height)];
            }
        } else {
            // If we have a cached image provider, try to get the last frame from them
            CGImageRef previousFrame = [cacheProvider cachedFrameImageAtIndex:index - 1];
            if (previousFrame) {
                // We need an iterator from the previous frame to dispose to background if
                // necessary.
                WebPDemuxReleaseIterator(&previousIterator);
                WebPDemuxGetFrame(_demux, (int)index, &previousIterator);
                CGRect previousFrameRect = CGRectMake(previousIterator.x_offset, _height - previousIterator.height - previousIterator.y_offset, previousIterator.width, previousIterator.height);
                canvas = [self canvasWithPreviousFrame:previousFrame
                                     previousFrameRect:previousFrameRect
                                    clearPreviousFrame:previousIterator.dispose_method == WEBP_MUX_DISPOSE_BACKGROUND
                                       backgroundColor:_backgroundColor
                                                 image:imageRef
                                     clearCurrentFrame:iterator.blend_method == WEBP_MUX_NO_BLEND
                                                atRect:CGRectMake(iterator.x_offset, iterator.y_offset, iterator.width, iterator.height)];
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
                CGContextSetFillColorWithColor(context, _backgroundColor);
                
                while (previousIterator.frame_num <= iterator.frame_num) {
                    CGImageRef previousFrame = [self rawImageWithIterator:previousIterator];
                    if (previousFrame) {
                        CGRect previousFrameRect = CGRectMake(previousIterator.x_offset, _height - previousIterator.height - previousIterator.y_offset, previousIterator.width, previousIterator.height);
                        if (previousIterator.blend_method == WEBP_MUX_NO_BLEND) {
                            CGContextFillRect(context, previousFrameRect);
                        }
                      
                        if (previousIterator.frame_num == iterator.frame_num) {
                            CGContextDrawImage(context, previousFrameRect, previousFrame);
                            // We have to break here because we're not getting the next frame! Basically
                            // the while loop is a sham and only here to illustrate what we want to iterate.
                            break;
                        } else {
                            if (previousIterator.dispose_method == WEBP_MUX_DISPOSE_BACKGROUND) {
                                CGContextFillRect(context, previousFrameRect);
                            } else {
                                CGContextDrawImage(context, previousFrameRect, previousFrame);
                            }
                            WebPDemuxNextFrame(&previousIterator);
                        }
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
