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
    uint32_t _flags;
    BOOL _hasAlpha;
    size_t _frameCount;
    size_t _loopCount;
    CFTimeInterval *_durations;
    NSError *_error;
}

@end

static void releaseData(void *info, const void *data, size_t size)
{
    free((void *)data);
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
            _flags = WebPDemuxGetI(_demux, WEBP_FF_FORMAT_FLAGS);
            _hasAlpha = _flags & ALPHA_FLAG;
            _durations = malloc(sizeof(CFTimeInterval) * _frameCount);
            
            // Iterate over the frames to gather duration
            WebPIterator iter;
            if (WebPDemuxGetFrame(_demux, 1, &iter)) {
                do {
                    _durations[iter.frame_num - 1] = iter.duration;
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

- (NSError *)error
{
    return _error;
}

- (CFTimeInterval)durationAtIndex:(NSUInteger)index
{
    return _durations[index];
}

- (CFTimeInterval)totalDuration
{
    static CFTimeInterval totalDuration = 0;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        for (NSUInteger idx = 0; idx < _frameCount; idx++) {
            totalDuration += _durations[idx];
        }
    });
    return totalDuration;
}

- (CGImageRef)imageAtIndex:(NSUInteger)index
{
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
            imageRef = CGImageCreate(_width,
                                     _height,
                                     8,
                                     8 * pixelLength,
                                     pixelLength * _width,
                                     colorSpaceRef,
                                     bitmapInfo,
                                     provider,
                                     NULL,
                                     NO,
                                     renderingIntent);
            
            CFAutorelease(imageRef);
            CGColorSpaceRelease(colorSpaceRef);
            CGDataProviderRelease(provider);
        }
        WebPDemuxReleaseIterator(&iter);
    }
    
    return imageRef;
}

@end

#endif
