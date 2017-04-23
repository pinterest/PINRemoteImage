//
//  PINImage+GIF.m
//  PINRemoteImage
//
//  Created by ganzy on 2017/04/22.
//  Copyright © 2017 Pinterest. All rights reserved.
//

#import "PINImage+GIF.h"
@import ImageIO;

@implementation PINImage (GIF)

#if PIN_TARGET_IOS

static NSTimeInterval frameDurationAtIndex(CGImageSourceRef source, size_t index)
{
    const CFDictionaryRef properties = CGImageSourceCopyPropertiesAtIndex(source, index, NULL);
    if (!properties) {
        return 0;
    }

    CFDictionaryRef gifProperties = CFDictionaryGetValue(properties, kCGImagePropertyGIFDictionary);
    if (!gifProperties) {
        CFRelease(properties);
        return 0;
    }

    CFNumberRef number = CFDictionaryGetValue(gifProperties, kCGImagePropertyGIFUnclampedDelayTime) ?: CFDictionaryGetValue(gifProperties, kCGImagePropertyGIFDelayTime);
    if (!number) {
        CFRelease(properties);
        return 0;
    }

    NSTimeInterval interval;
    if (!CFNumberGetValue(number, kCFNumberDoubleType, &interval)) {
        CFRelease(properties);
        return 0;
    }

    CFRelease(properties);
    return interval;
}

#endif

+ (PINImage *)pin_imageWithGIFData:(NSData *)gifData
{
    if (!gifData) {
        return nil;
    }

#if PIN_TARGET_IOS

    const CGImageSourceRef imageSource = CGImageSourceCreateWithData((CFDataRef)gifData, NULL);
    if (!imageSource) {
        return nil;
    }

    const size_t numberOfFrames = CGImageSourceGetCount(imageSource);
    if (numberOfFrames <= 0) {
        CFRelease(imageSource);
        return nil;
    }

    NSMutableArray *images = [NSMutableArray arrayWithCapacity:numberOfFrames];
    NSTimeInterval totalDuration = 0;

    for (size_t index = 0; index < numberOfFrames; index++) {
        CGImageRef image = CGImageSourceCreateImageAtIndex(imageSource, index, NULL);
        if (!image) {
            continue;
        }
        totalDuration += frameDurationAtIndex(imageSource, index);
        [images addObject:[UIImage imageWithCGImage:image]];
        CGImageRelease(image);
    }

    CFRelease(imageSource);

    return [UIImage animatedImageWithImages:images duration:totalDuration];

#elif PIN_TARGET_MAC

    return [PINImage imageWithData:gifData];

#endif
}

@end
