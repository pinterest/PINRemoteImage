//
//  PINGIFAnimatedImage.m
//  PINRemoteImage
//
//  Created by Garrett Moon on 9/17/17.
//  Copyright © 2017 Pinterest. All rights reserved.
//

#import "PINGIFAnimatedImage.h"

#import <ImageIO/ImageIO.h>
#if PIN_TARGET_IOS
#import <MobileCoreServices/UTCoreTypes.h>
#elif PIN_TARGET_MAC
#import <CoreServices/CoreServices.h>
#endif

#import "PINImage+DecodedImage.h"

@interface PINGIFAnimatedImage ()
{
    NSData *_animatedImageData;
    CGImageSourceRef _imageSource;
    uint32_t _width;
    uint32_t _height;
    BOOL _hasAlpha;
    size_t _frameCount;
    size_t _loopCount;
    CFTimeInterval *_durations;
    NSError *_error;
}
@end

@implementation PINGIFAnimatedImage

- (instancetype)initWithAnimatedImageData:(NSData *)animatedImageData
{
    if (self = [super init]) {
        _animatedImageData = animatedImageData;
        _imageSource =
            CGImageSourceCreateWithData((CFDataRef)animatedImageData,
                                        (CFDictionaryRef)@{(__bridge NSString *)kCGImageSourceTypeIdentifierHint:
                                                               (__bridge NSString *)kUTTypeGIF,
                                                           (__bridge NSString *)kCGImageSourceShouldCache:
                                                               (__bridge NSNumber *)kCFBooleanFalse});
        if (_imageSource) {
            _frameCount = (uint32_t)CGImageSourceGetCount(_imageSource);
            NSDictionary *imageProperties = (__bridge_transfer NSDictionary *)CGImageSourceCopyProperties(_imageSource, nil);
            _loopCount = (uint32_t)[[[imageProperties objectForKey:(__bridge NSString *)kCGImagePropertyGIFDictionary]
                                     objectForKey:(__bridge NSString *)kCGImagePropertyGIFLoopCount] unsignedLongValue];
            _durations = malloc(sizeof(CFTimeInterval) * _frameCount);
            imageProperties = (__bridge_transfer NSDictionary *)
                CGImageSourceCopyPropertiesAtIndex(_imageSource,
                                                   0,
                                                   (CFDictionaryRef)@{(__bridge NSString *)kCGImageSourceShouldCache:
                                                                          (__bridge NSNumber *)kCFBooleanFalse});
            _width = (uint32_t)[(NSNumber *)imageProperties[(__bridge NSString *)kCGImagePropertyPixelWidth] unsignedIntegerValue];
            _height = (uint32_t)[(NSNumber *)imageProperties[(__bridge NSString *)kCGImagePropertyPixelHeight] unsignedIntegerValue];
            
            for (NSUInteger frameIdx = 0; frameIdx < _frameCount; frameIdx++) {
                _durations[frameIdx] = [PINGIFAnimatedImage frameDurationAtIndex:frameIdx source:_imageSource];
            }
        }
    }
    return self;
}

+ (Float32)frameDurationAtIndex:(NSUInteger)index source:(CGImageSourceRef)source
{
    Float32 frameDuration = kPINAnimatedImageDefaultDuration;
    NSDictionary *frameProperties = (__bridge_transfer NSDictionary *)CGImageSourceCopyPropertiesAtIndex(source, index, nil);
    // use unclamped delay time before delay time before default
    NSNumber *unclamedDelayTime = frameProperties[(__bridge NSString *)kCGImagePropertyGIFDictionary][(__bridge NSString *)kCGImagePropertyGIFUnclampedDelayTime];
    if (unclamedDelayTime != nil) {
        frameDuration = [unclamedDelayTime floatValue];
    } else {
        NSNumber *delayTime = frameProperties[(__bridge NSString *)kCGImagePropertyGIFDictionary][(__bridge NSString *)kCGImagePropertyGIFDelayTime];
        if (delayTime != nil) {
            frameDuration = [delayTime floatValue];
        }
    }
    
    static dispatch_once_t onceToken;
    static Float32 maximumFrameDuration;
    dispatch_once(&onceToken, ^{
        maximumFrameDuration = 1.0 / [PINAnimatedImage maximumFramesPerSecond];
    });
    
    if (frameDuration < maximumFrameDuration) {
        frameDuration = kPINAnimatedImageDefaultDuration;
    }
    
    return frameDuration;
}

- (void)dealloc
{
    if (_imageSource) {
        CFRelease(_imageSource);
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
    return _width * _height * 3;
}

- (NSError *)error
{
    return _error;
}

- (CFTimeInterval)durationAtIndex:(NSUInteger)index
{
    return _durations[index];
}

- (CGImageRef)imageAtIndex:(NSUInteger)index cacheProvider:(nullable id<PINCachedAnimatedFrameProvider>)cacheProvider
{
    // I believe this is threadsafe as CGImageSource *seems* immutable…
    CGImageRef imageRef =
        CGImageSourceCreateImageAtIndex(_imageSource,
                                        index,
                                        (CFDictionaryRef)@{(__bridge NSString *)kCGImageSourceShouldCache:
                                                               (__bridge NSNumber *)kCFBooleanFalse});
    if (imageRef) {
        CGImageRef decodedImageRef = [PINImage pin_decodedImageRefWithCGImageRef:imageRef];
        CGImageRelease(imageRef);
        imageRef = decodedImageRef;
    }
    
    return imageRef;
}

@end
