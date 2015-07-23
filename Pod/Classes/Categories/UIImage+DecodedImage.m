//
//  UIImage+DecodedImage.m
//  Pods
//
//  Created by Garrett Moon on 11/19/14.
//
//

#import "UIImage+DecodedImage.h"

#import <ImageIO/ImageIO.h>

#if __has_include(<webp/decode.h>)
#import "UIImage+WebP.h"
#endif

#import "NSData+ImageDetectors.h"


@implementation UIImage (DecodedImage)

+ (UIImage *)decodedImageWithData:(NSData *)data
{
    return [self decodedImageWithData:data skipDecodeIfPossible:NO];
}

+ (UIImage *)decodedImageWithData:(NSData *)data skipDecodeIfPossible:(BOOL)skipDecodeIfPossible
{
    if (data == nil) {
        return nil;
    }
    
    if ([data isGIF]) {
        return [UIImage imageWithData:data];
    }
#if __has_include(<webp/decode.h>)
    if ([data isWebP]) {
        return [UIImage imageWithWebPData:data];
    }
#endif
    
    if (skipDecodeIfPossible) {
        return [UIImage imageWithData:data];
    }
    
    UIImage *decodedImage = nil;
    
    CGImageSourceRef imageSourceRef = CGImageSourceCreateWithData((CFDataRef)data, NULL);
    if (imageSourceRef) {
        CGImageRef imageRef = CGImageSourceCreateImageAtIndex(imageSourceRef, 0, (CFDictionaryRef)@{(NSString *)kCGImageSourceShouldCache : (NSNumber *)kCFBooleanFalse});
        if (imageRef) {
            decodedImage = [self decodedImageWithCGImageRef:imageRef];
            
            CGImageRelease(imageRef);
        }
        
        CFRelease(imageSourceRef);
    }
    
    return decodedImage;
}

+ (UIImage *)decodedImageWithCGImageRef:(CGImageRef)imageRef
{
    BOOL opaque = YES;
    CGImageAlphaInfo alpha = CGImageGetAlphaInfo(imageRef);
    if (alpha == kCGImageAlphaFirst || alpha == kCGImageAlphaLast || alpha == kCGImageAlphaOnly || alpha == kCGImageAlphaPremultipliedFirst || alpha == kCGImageAlphaPremultipliedLast) {
        opaque = NO;
    }
    
    CGSize imageSize = CGSizeMake(CGImageGetWidth(imageRef), CGImageGetHeight(imageRef));
    UIGraphicsBeginImageContextWithOptions(imageSize, opaque, 1.0);
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    UIImage *decodedImage = nil;
    if (ctx) {
        CGContextScaleCTM(ctx, 1.0, -1.0);
        CGContextTranslateCTM(ctx, 0.0, -imageSize.height);
        CGContextDrawImage(ctx, CGRectMake(0, 0, imageSize.width, imageSize.height), imageRef);
        decodedImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    } else {
        decodedImage = [UIImage imageWithCGImage:imageRef];
    }
    
    return decodedImage;
}

@end
