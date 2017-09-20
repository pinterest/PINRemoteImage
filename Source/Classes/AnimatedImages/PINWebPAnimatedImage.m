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

#import <webp/demux.h>

@interface PINWebPAnimatedImage ()
{
    NSData *_animatedImageData;
    WebPData _underlyingData;
    WebPDemuxer *_demux;
    uint32_t _width;
    uint32_t _height;
    BOOL _hasAlpha;
    size_t _frameCount;
    size_t _loopCount;
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
            
            // Iterate over the frames to gather duration
            WebPIterator iter;
            if (WebPDemuxGetFrame(_demux, 1, &iter)) {
                do {
                    CFTimeInterval duration = iter.duration / 1000.0;
                    if (duration < kPINAnimatedImageMinimumDuration) {
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
    } if (_durations) {
        free(_durations);
    }
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

- (NSError *)error
{
    return _error;
}

- (CFTimeInterval)durationAtIndex:(NSUInteger)index
{
    return _durations[index];
}

- (CGImageRef)imageAtIndex:(NSUInteger)index
{
    // This all *appears* to be threadsafe as I believe demux is immutable…
    WebPIterator iter;
    CGImageRef imageRef = NULL;
    if (WebPDemuxGetFrame(_demux, (int)index, &iter)) {
        // ... (Consume 'iter'; e.g. Decode 'iter.fragment' with WebPDecode(),
        // ... and get other frame properties like width, height, offsets etc.
        // ... see 'struct WebPIterator' below for more info).
        uint8_t *data = NULL;
        int pixelLength = 0;
        
        if (_hasAlpha) {
            data = WebPDecodeRGBA(iter.fragment.bytes, iter.fragment.size, NULL, NULL);
            pixelLength = 4;
        } else {
            data = WebPDecodeRGB(iter.fragment.bytes, iter.fragment.size, NULL, NULL);
            pixelLength = 3;
        }
        
        if (data) {
            CGDataProviderRef provider = CGDataProviderCreateWithData(NULL, data, _width * _height * pixelLength, releaseData);
            
            CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
            CGBitmapInfo bitmapInfo = kCGBitmapByteOrderDefault;
            
            if (_hasAlpha) {
                bitmapInfo |= kCGImageAlphaLast;
            } else {
                bitmapInfo |= kCGImageAlphaNone;
            }
            
            CGColorRenderingIntent renderingIntent = kCGRenderingIntentDefault;
            imageRef = CGImageCreate(iter.width,
                                     iter.height,
                                     8,
                                     8 * pixelLength,
                                     pixelLength * iter.width,
                                     colorSpaceRef,
                                     bitmapInfo,
                                     provider,
                                     NULL,
                                     NO,
                                     renderingIntent);
            
            if (iter.x_offset != 0 || iter.y_offset != 0 || iter.width != _width || iter.height != _height) {
                // Canvas size is different, we need to copy to a canvas :/
                CGContextRef context = CGBitmapContextCreate(NULL,
                                                             _width,
                                                             _height,
                                                             8,
                                                             0,
                                                             colorSpaceRef,
                                                             _hasAlpha ? kCGImageAlphaPremultipliedFirst : kCGImageAlphaNone);
                
                CGContextDrawImage(context, CGRectMake(iter.x_offset, _height - iter.height - iter.y_offset, iter.width, iter.height), imageRef);
                CGImageRelease(imageRef);
                
                imageRef = CGBitmapContextCreateImage(context);
                CGContextRelease(context);
            }
            
            if (imageRef) {
                CFAutorelease(imageRef);
            }
            
            CGColorSpaceRelease(colorSpaceRef);
            CGDataProviderRelease(provider);
        }
        WebPDemuxReleaseIterator(&iter);
    }
    
    return imageRef;
}

@end

#endif
