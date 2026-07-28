//
//  PINWebPAnimatedImage.m
//  PINRemoteImage
//
//  Created by Garrett Moon on 9/14/17.
//  Copyright © 2017 Pinterest. All rights reserved.
//

#import <PINRemoteImage/PINWebPAnimatedImage.h>

#if PIN_WEBP

#import <ImageIO/ImageIO.h>
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>
#if PIN_TARGET_IOS
#import <MobileCoreServices/UTCoreTypes.h>
#elif PIN_TARGET_MAC
#import <CoreServices/CoreServices.h>
#endif

#import <PINRemoteImage/PINImage+DecodedImage.h>
#import <PINRemoteImage/NSData+ImageDetectors.h>

@interface PINWebPAnimatedImage ()
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
    NSLock *_decodeLock; // serializes frame decodes on _imageSource
}
@end

@implementation PINWebPAnimatedImage

- (instancetype)initWithAnimatedImageData:(NSData *)animatedImageData
{
    if (self = [super init]) {
        _animatedImageData = animatedImageData;
        _decodeLock = [[NSLock alloc] init];

        _imageSource =
            CGImageSourceCreateWithData((CFDataRef)animatedImageData,
                                        (CFDictionaryRef)@{(__bridge NSString *)kCGImageSourceTypeIdentifierHint:
                                                               [UTTypeWebP identifier],
                                                           (__bridge NSString *)kCGImageSourceShouldCache:
                                                               (__bridge NSNumber *)kCFBooleanFalse});
        if (_imageSource && [animatedImageData pin_isWebP]) {
            _frameCount = (uint32_t)CGImageSourceGetCount(_imageSource);
            NSDictionary *imageProperties = (__bridge_transfer NSDictionary *)CGImageSourceCopyProperties(_imageSource, nil);
            _loopCount = (uint32_t)[[[imageProperties objectForKey:(__bridge NSString *)kCGImagePropertyWebPDictionary]
                                     objectForKey:(__bridge NSString *)kCGImagePropertyWebPLoopCount] unsignedLongValue];
            _durations = malloc(sizeof(CFTimeInterval) * _frameCount);
            imageProperties = (__bridge_transfer NSDictionary *)
                CGImageSourceCopyPropertiesAtIndex(_imageSource,
                                                   0,
                                                   (CFDictionaryRef)@{(__bridge NSString *)kCGImageSourceShouldCache:
                                                                          (__bridge NSNumber *)kCFBooleanFalse});
            _width = (uint32_t)[(NSNumber *)imageProperties[(__bridge NSString *)kCGImagePropertyPixelWidth] unsignedIntegerValue];
            _height = (uint32_t)[(NSNumber *)imageProperties[(__bridge NSString *)kCGImagePropertyPixelHeight] unsignedIntegerValue];
            
            for (NSUInteger frameIdx = 0; frameIdx < _frameCount; frameIdx++) {
                _durations[frameIdx] = [PINWebPAnimatedImage frameDurationAtIndex:frameIdx source:_imageSource];
            }
        } else {
            return nil;
        }
    }
    return self;
}

+ (Float32)frameDurationAtIndex:(NSUInteger)index source:(CGImageSourceRef)source
{
    Float32 frameDuration = kPINAnimatedImageDefaultDuration;
    NSDictionary *frameProperties = (__bridge_transfer NSDictionary *)CGImageSourceCopyPropertiesAtIndex(source, index, nil);
    // use unclamped delay time before delay time before default
    NSNumber *unclamedDelayTime = frameProperties[(__bridge NSString *)kCGImagePropertyWebPDictionary][(__bridge NSString *)kCGImagePropertyWebPUnclampedDelayTime];
    if (unclamedDelayTime != nil) {
        frameDuration = [unclamedDelayTime floatValue];
    } else {
        NSNumber *delayTime = frameProperties[(__bridge NSString *)kCGImagePropertyWebPDictionary][(__bridge NSString *)kCGImagePropertyWebPDelayTime];
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
    return _width * _height * 4;
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
    // same hardening as PINGIFAnimatedImage — serialize
    // all ImageIO calls on the shared source (including the status query, which
    // advances parser state), and refuse affirmatively damaged frames. CGImageSource
    // is not safe for concurrent lazy decodes of the same source, despite the
    // optimistic comment this replaced.
    [_decodeLock lock];
    CGImageSourceStatus frameStatus = CGImageSourceGetStatusAtIndex(_imageSource, index);
    if (frameStatus == kCGImageStatusInvalidData || frameStatus == kCGImageStatusUnexpectedEOF) {
        [_decodeLock unlock];
        return NULL;
    }

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
    [_decodeLock unlock];

    return imageRef;
}

@end

#endif
