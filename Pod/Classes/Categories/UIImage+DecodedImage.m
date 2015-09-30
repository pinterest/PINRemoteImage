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




@implementation UIImage (PINDecodedImage)

+ (UIImage *)pin_decodedImageWithData:(NSData *)data
{
    return [self pin_decodedImageWithData:data skipDecodeIfPossible:NO];
}

+ (UIImage *)pin_decodedImageWithData:(NSData *)data skipDecodeIfPossible:(BOOL)skipDecodeIfPossible
{
    if (data == nil) {
        return nil;
    }
    
    if ([data pin_isGIF]) {
        return [UIImage imageWithData:data];
    }
#if __has_include(<webp/decode.h>)
    if ([data pin_isWebP]) {
        return [UIImage pin_imageWithWebPData:data];
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
            
            UIImageOrientation orientation = pin_UIImageOrienationFromImageSource(imageSourceRef);
            
            decodedImage = [self pin_decodedImageWithCGImageRef:imageRef orientation:orientation];
            
            CGImageRelease(imageRef);
        }
        
        CFRelease(imageSourceRef);
    }
    
    return decodedImage;
}

+ (UIImage *)pin_decodedImageWithCGImageRef:(CGImageRef)imageRef
{
    return [self pin_decodedImageWithCGImageRef:imageRef orientation:UIImageOrientationUp];
}

+ (UIImage *)pin_decodedImageWithCGImageRef:(CGImageRef)imageRef orientation:(UIImageOrientation) orientation
{
    BOOL opaque = YES;
    CGImageAlphaInfo alpha = CGImageGetAlphaInfo(imageRef);
    if (alpha == kCGImageAlphaFirst || alpha == kCGImageAlphaLast || alpha == kCGImageAlphaOnly || alpha == kCGImageAlphaPremultipliedFirst || alpha == kCGImageAlphaPremultipliedLast) {
        opaque = NO;
    }
    
    CGSize imageSize = CGSizeMake(CGImageGetWidth(imageRef), CGImageGetHeight(imageRef));
    
    CGBitmapInfo info = opaque ? (kCGImageAlphaNoneSkipFirst | kCGBitmapByteOrder32Host) : (kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrder32Host);
    CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceRGB();
    
    //Use UIGraphicsBeginImageContext parameters from docs: https://developer.apple.com/library/ios/documentation/UIKit/Reference/UIKitFunctionReference/#//apple_ref/c/func/UIGraphicsBeginImageContextWithOptions
    CGContextRef ctx = CGBitmapContextCreate(NULL, imageSize.width, imageSize.height,
                                             8,
                                             0,
                                             colorspace,
                                             info);
    
    CGColorSpaceRelease(colorspace);
    
    UIImage *decodedImage = nil;
    if (ctx) {
        CGContextDrawImage(ctx, CGRectMake(0, 0, imageSize.width, imageSize.height), imageRef);
        
        CGImageRef newImage = CGBitmapContextCreateImage(ctx);
        
        decodedImage = [UIImage imageWithCGImage:newImage scale:1.0 orientation:orientation];
        
        CGImageRelease(newImage);
        CGContextRelease(ctx);
        
    } else {
        decodedImage = [UIImage imageWithCGImage:imageRef scale:1.0 orientation:orientation];
    }
    
    return decodedImage;
}


UIImageOrientation pin_UIImageOrienationFromImageSource(CGImageSourceRef imageSourceRef) {
    UIImageOrientation orientation = UIImageOrientationUp;
    
    if (imageSourceRef != nil) {
        NSDictionary *dict = (NSDictionary *)CFBridgingRelease(CGImageSourceCopyPropertiesAtIndex(imageSourceRef, 0, NULL));
        
        if (dict != nil) {
            
            NSNumber* exifOrientation = dict[(id)kCGImagePropertyOrientation];
            if (exifOrientation != nil) {
                
                switch (exifOrientation.intValue) {
                    case 1: /*kCGImagePropertyOrientationUp*/
                        orientation = UIImageOrientationUp;
                        break;
                        
                    case 2: /*kCGImagePropertyOrientationUpMirrored*/
                        orientation = UIImageOrientationUpMirrored;
                        break;
                        
                    case 3: /*kCGImagePropertyOrientationDown*/
                        orientation = UIImageOrientationDown;
                        break;
                        
                    case 4: /*kCGImagePropertyOrientationDownMirrored*/
                        orientation = UIImageOrientationDownMirrored;
                        break;
                    case 5: /*kCGImagePropertyOrientationLeftMirrored*/
                        orientation = UIImageOrientationLeftMirrored;
                        break;
                        
                    case 6: /*kCGImagePropertyOrientationRight*/
                        orientation = UIImageOrientationRight;
                        break;
                        
                    case 7: /*kCGImagePropertyOrientationRightMirrored*/
                        orientation = UIImageOrientationRightMirrored;
                        break;
                        
                    case 8: /*kCGImagePropertyOrientationLeft*/
                        orientation = UIImageOrientationLeft;
                        break;
                        
                    default:
                        break;
                }
            }
        }
    }
    
    return orientation;
}


@end

@implementation UIImage (PINDecodedImage_Deprecated)

+ (UIImage *)decodedImageWithData:(NSData *)data
{
    return [self pin_decodedImageWithData:data];
}

+ (UIImage *)decodedImageWithData:(NSData *)data skipDecodeIfPossible:(BOOL)skipDecodeIfPossible
{
    return [self pin_decodedImageWithData:data skipDecodeIfPossible:skipDecodeIfPossible];
}

+ (UIImage *)decodedImageWithCGImageRef:(CGImageRef)imageRef
{
    return [self pin_decodedImageWithCGImageRef:imageRef];
}

@end
