//
//  UIImage+ScaledImage.m
//  Pods
//
//  Created by Michael Schneider on 2/9/17.
//
//

#import "PINImage+ScaledImage.h"

static inline PINImage *PINScaledImageForKey(NSString * __nullable key, PINImage * __nullable image) {
    if (image == nil) {
        return nil;
    }
    
#if PIN_TARGET_IOS
    
    NSCAssert(image.CGImage != NULL, @"CGImage should not be NULL");
    
    CGFloat scale = 1.0;
    if (key.length >= 8) {
        if ([key rangeOfString:@"_2x."].location != NSNotFound ||
            [key rangeOfString:@"@2x."].location != NSNotFound) {
            scale = 2.0;
        }
        
        if ([key rangeOfString:@"_3x."].location != NSNotFound ||
            [key rangeOfString:@"@3x."].location != NSNotFound) {
            scale = 3.0;
        }
    }
    
    if (scale != image.scale) {
        return [[UIImage alloc] initWithCGImage:image.CGImage scale:scale orientation:image.imageOrientation];
    }
    
    return image;

#elif PIN_TARGET_MAC
    return image;
#endif
}

@implementation PINImage (ScaledImage)

- (PINImage *)pin_scaledImageForKey:(NSString *)key
{
    return PINScaledImageForKey(key, self);
}

+ (PINImage *)pin_scaledImageForImage:(PINImage *)image withKey:(NSString *)key
{
    return PINScaledImageForKey(key, image);
}

@end
