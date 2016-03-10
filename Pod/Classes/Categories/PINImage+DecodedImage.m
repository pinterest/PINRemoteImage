//
//  UIImage+DecodedImage.m
//  Pods
//
//  Created by Garrett Moon on 11/19/14.
//
//

#import "PINImage+DecodedImage.h"

#import <ImageIO/ImageIO.h>

#ifdef PIN_WEBP
#import "PINImage+WebP.h"
#endif

#import "NSData+ImageDetectors.h"

#ifdef __MAC_OS_X_VERSION_MIN_REQUIRED
@implementation NSImage (PINiOSMapping)

- (CGImageRef)CGImage
{
    NSGraphicsContext *context = [NSGraphicsContext currentContext];
    NSRect rect = NSMakeRect(0.0, 0.0, self.size.width, self.size.height);
    return [self CGImageForProposedRect:&rect context:context hints:NULL];
}

+ (NSImage *)imageWithData:(NSData *)imageData;
{
    return [[self alloc] initWithData:imageData];
}

+ (NSImage *)imageWithContentsOfFile:(NSString *)path
{
    return path ? [[self alloc] initWithContentsOfFile:path] : nil;
}

+ (NSImage *)imageWithCGImage:(CGImageRef)imageRef
{
    return [[self alloc] initWithCGImage:imageRef size:CGSizeZero];
}

@end
#endif

NSData * __nullable PINImageJPEGRepresentation(PINImage * __nonnull image, CGFloat compressionQuality)
{
#if TARGET_OS_IPHONE || TARGET_OS_TV
    return UIImageJPEGRepresentation(image, compressionQuality);
#elif TARGET_OS_MAC
    NSBitmapImageRep *imageRep = [NSBitmapImageRep imageRepWithData:[image TIFFRepresentation]];
    NSDictionary *imageProperties = @{NSImageCompressionFactor : @(compressionQuality)};
    return [imageRep representationUsingType:NSJPEGFileType properties:imageProperties];
#endif
}

NSData * __nullable PINImagePNGRepresentation(PINImage * __nonnull image) {
#if TARGET_OS_IPHONE || TARGET_OS_TV
    return UIImagePNGRepresentation(image);
#elif TARGET_OS_MAC
    NSBitmapImageRep *imageRep = [NSBitmapImageRep imageRepWithData:[image TIFFRepresentation]];
    NSDictionary *imageProperties = @{NSImageCompressionFactor : @1};
    return [imageRep representationUsingType:NSPNGFileType properties:imageProperties];
#endif
}


@implementation PINImage (PINDecodedImage)

+ (PINImage *)pin_decodedImageWithData:(NSData *)data
{
    return [self pin_decodedImageWithData:data skipDecodeIfPossible:NO];
}

+ (PINImage *)pin_decodedImageWithData:(NSData *)data skipDecodeIfPossible:(BOOL)skipDecodeIfPossible
{
    if (data == nil) {
        return nil;
    }
    
    if ([data pin_isGIF]) {
        return [PINImage imageWithData:data];
    }
#ifdef PIN_WEBP
    if ([data pin_isWebP]) {
        return [PINImage pin_imageWithWebPData:data];
    }
#endif
    
    if (skipDecodeIfPossible) {
        return [PINImage imageWithData:data];
    }
    
    PINImage *decodedImage = nil;
    
    CGImageSourceRef imageSourceRef = CGImageSourceCreateWithData((CFDataRef)data, NULL);
    
    if (imageSourceRef) {
        CGImageRef imageRef = CGImageSourceCreateImageAtIndex(imageSourceRef, 0, (CFDictionaryRef)@{(NSString *)kCGImageSourceShouldCache : (NSNumber *)kCFBooleanFalse});
        if (imageRef) {
#if TARGET_OS_IPHONE || TARGET_OS_TV
            UIImageOrientation orientation = pin_UIImageOrienationFromImageSource(imageSourceRef);
            
            decodedImage = [self pin_decodedImageWithCGImageRef:imageRef orientation:orientation];
            
#elif TARGET_OS_MAC
            decodedImage = [self pin_decodedImageWithCGImageRef:imageRef];
#endif
            
            CGImageRelease(imageRef);
        }
        
        CFRelease(imageSourceRef);
    }
    
    return decodedImage;
}

+ (PINImage *)pin_decodedImageWithCGImageRef:(CGImageRef)imageRef
{
#if TARGET_OS_IPHONE || TARGET_OS_TV
    return [self pin_decodedImageWithCGImageRef:imageRef orientation:UIImageOrientationUp];
}

+ (PINImage *)pin_decodedImageWithCGImageRef:(CGImageRef)imageRef orientation:(UIImageOrientation)orientation
{
#endif
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
    
    PINImage *decodedImage = nil;
    if (ctx) {
        CGContextDrawImage(ctx, CGRectMake(0, 0, imageSize.width, imageSize.height), imageRef);
        
        CGImageRef newImage = CGBitmapContextCreateImage(ctx);
        
#if TARGET_OS_IPHONE || TARGET_OS_TV
        decodedImage = [UIImage imageWithCGImage:newImage scale:1.0 orientation:orientation];
#elif TARGET_OS_MAC
        decodedImage = [[NSImage alloc] initWithCGImage:newImage size:imageSize];
#endif
        CGImageRelease(newImage);
        CGContextRelease(ctx);
        
    } else {
#if TARGET_OS_IPHONE || TARGET_OS_TV
        decodedImage = [UIImage imageWithCGImage:imageRef scale:1.0 orientation:orientation];
#elif TARGET_OS_MAC
        decodedImage = [[NSImage alloc] initWithCGImage:imageRef size:imageSize];
#endif
    }
    
    return decodedImage;
}

#if TARGET_OS_IPHONE || TARGET_OS_TV
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

#endif

@end
