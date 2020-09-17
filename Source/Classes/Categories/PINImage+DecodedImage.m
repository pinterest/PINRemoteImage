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

NS_INLINE BOOL pin_CGImageRefIsOpaque(CGImageRef imageRef) {
    CGImageAlphaInfo alpha = CGImageGetAlphaInfo(imageRef);
    switch (alpha) {
        case kCGImageAlphaNone:
        case kCGImageAlphaNoneSkipLast:
        case kCGImageAlphaNoneSkipFirst:
            return YES;
        default:
            return NO;
    }
}

#if PIN_TARGET_IOS
NS_INLINE void pin_degreesFromOrientation(UIImageOrientation orientation, void (^completion)(CGFloat degrees, BOOL horizontalFlip, BOOL verticalFlip)) {
    switch (orientation) {
        case UIImageOrientationUp: // default orientation
            completion(0.0, NO, NO);
            break;
        case UIImageOrientationDown: // 180 deg rotation
            completion(180.0, NO, NO);
            break;
        case UIImageOrientationLeft:
            completion(270.0, NO, NO); // 90 deg CCW
            break;
        case UIImageOrientationRight:
            completion(90.0, NO, NO); // 90 deg CW
            break;
        case UIImageOrientationUpMirrored: // as above but image mirrored along other axis. horizontal flip
            completion(0.0, YES, NO);
            break;
        case UIImageOrientationDownMirrored: // horizontal flip
            completion(180.0, YES, NO);
            break;
        case UIImageOrientationLeftMirrored: // vertical flip
            completion(270.0, NO, YES);
            break;
        case UIImageOrientationRightMirrored: // vertical flip
            completion(90.0, NO, YES);
            break;
    }
}
#endif

#if !PIN_TARGET_IOS
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
#if PIN_TARGET_IOS
    return UIImageJPEGRepresentation(image, compressionQuality);
#elif PIN_TARGET_MAC
    NSBitmapImageRep *imageRep = [NSBitmapImageRep imageRepWithData:[image TIFFRepresentation]];
    NSDictionary *imageProperties = @{NSImageCompressionFactor : @(compressionQuality)};
    return [imageRep representationUsingType:NSJPEGFileType properties:imageProperties];
#endif
}

NSData * __nullable PINImagePNGRepresentation(PINImage * __nonnull image) {
#if PIN_TARGET_IOS
    return UIImagePNGRepresentation(image);
#elif PIN_TARGET_MAC
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
    
#if PIN_WEBP
    if ([data pin_isWebP]) {
        return [PINImage pin_imageWithWebPData:data];
    }
#endif
    
    PINImage *decodedImage = nil;
    
    CGImageSourceRef imageSourceRef = CGImageSourceCreateWithData((CFDataRef)data, NULL);
    
    if (imageSourceRef) {
        CGImageRef imageRef = CGImageSourceCreateImageAtIndex(imageSourceRef, 0, (CFDictionaryRef)@{(NSString *)kCGImageSourceShouldCache : (NSNumber *)kCFBooleanFalse});
        if (imageRef) {
#if PIN_TARGET_IOS
            UIImageOrientation orientation = pin_UIImageOrientationFromImageSource(imageSourceRef);
            if (skipDecodeIfPossible) {
                decodedImage = [PINImage imageWithCGImage:imageRef scale:1.0 orientation:orientation];
            } else {
                decodedImage = [self pin_decodedImageWithCGImageRef:imageRef orientation:orientation];
            }
#elif PIN_TARGET_MAC
            if (skipDecodeIfPossible) {
                CGSize imageSize = CGSizeMake(CGImageGetWidth(imageRef), CGImageGetHeight(imageRef));
                decodedImage = [[NSImage alloc] initWithCGImage:imageRef size:imageSize];
            } else {
                decodedImage = [self pin_decodedImageWithCGImageRef:imageRef];
            }
#endif
            CGImageRelease(imageRef);
        }
        
        CFRelease(imageSourceRef);
    }
    
    return decodedImage;
}

+ (PINImage *)pin_decodedImageWithCGImageRef:(CGImageRef)imageRef
{
#if PIN_TARGET_IOS
    return [self pin_decodedImageWithCGImageRef:imageRef orientation:UIImageOrientationUp];
}

+ (PINImage *)pin_decodedImageWithCGImageRef:(CGImageRef)imageRef orientation:(UIImageOrientation)orientation
{
#endif
#if PIN_TARGET_IOS
    if (@available(iOS 10.0, tvOS 10.0, *)) {
        return [self pin_decodedImageUsingGraphicsImageRendererRefWithCGImageRef:imageRef scale:1.0 orientation:orientation];
    } else {
        return [UIImage imageWithCGImage:[self pin_decodedImageRefWithCGImageRef:imageRef] scale:1.0 orientation:orientation];
    }
#elif PIN_TARGET_MAC
    return [[NSImage alloc] initWithCGImage:[self pin_decodedImageRefWithCGImageRef:imageRef] size:NSZeroSize];
#endif
}

#if PIN_TARGET_IOS
+ (PINImage *)pin_decodedImageUsingGraphicsImageRendererRefWithCGImageRef:(CGImageRef)imageRef
                                                                    scale:(CGFloat)scale
                                                              orientation:(UIImageOrientation)orientation API_AVAILABLE(ios(10.0), tvos(10.0)) {
    UIGraphicsImageRendererFormat *format = nil;
    if (@available(iOS 11.0, tvOS 11.0, *)) {
        format = [UIGraphicsImageRendererFormat preferredFormat];
    } else {
        format = [UIGraphicsImageRendererFormat defaultFormat];
    }
    
    format.scale = scale;
    format.opaque = pin_CGImageRefIsOpaque(imageRef);
    
    __block CGFloat radians = 0.0;
    __block BOOL doHorizontalFlip = NO;
    __block BOOL doVerticalFlip = NO;
    
    pin_degreesFromOrientation(orientation, ^(CGFloat degrees, BOOL horizontalFlip, BOOL verticalFlip) {
        // Convert degrees to radians
        radians = [[[NSMeasurement alloc] initWithDoubleValue:degrees
                                                         unit:[NSUnitAngle degrees]]
                   measurementByConvertingToUnit:[NSUnitAngle radians]].doubleValue;
        doHorizontalFlip = horizontalFlip;
        doVerticalFlip = verticalFlip;
    });
    
    // Create rotation out of radians
    CGAffineTransform transform = CGAffineTransformMakeRotation(radians);
    
    // Grab image size
    CGSize imageSize = CGSizeMake(CGImageGetWidth(imageRef), CGImageGetHeight(imageRef));
    
    // Rotate rect by transformation
    CGRect rotatedRect = CGRectApplyAffineTransform(CGRectMake(0.0, 0.0, imageSize.width, imageSize.height), transform);
    
    // Use graphics renderer to render image
    UIGraphicsImageRenderer *renderer = [[UIGraphicsImageRenderer alloc] initWithSize:rotatedRect.size format:format];
    
    return [renderer imageWithActions:^(UIGraphicsImageRendererContext * _Nonnull rendererContext) {
        CGContextRef ctx = rendererContext.CGContext;
        
        // Flip the default coordinate system for iOS/tvOS:  https://developer.apple.com/library/archive/documentation/2DDrawing/Conceptual/DrawingPrintingiOS/GraphicsDrawingOverview/GraphicsDrawingOverview.html#//apple_ref/doc/uid/TP40010156-CH14-SW4
        CGContextTranslateCTM(ctx, rotatedRect.size.width / 2.0, rotatedRect.size.height / 2.0);
        CGContextScaleCTM(ctx, (doHorizontalFlip ? -1.0 : 1.0), (doVerticalFlip ? 1.0 : -1.0));
        
        // Apply transformation
        CGContextConcatCTM(ctx, transform);
        
        // Draw image
        CGContextDrawImage(ctx, CGRectMake(-(imageSize.width / 2.0), -(imageSize.height / 2.0), imageSize.width, imageSize.height), imageRef);
    }];
}
#endif

+ (CGImageRef)pin_decodedImageRefWithCGImageRef:(CGImageRef)imageRef
{
    CGSize imageSize = CGSizeMake(CGImageGetWidth(imageRef), CGImageGetHeight(imageRef));
    
    CGBitmapInfo info = pin_CGImageRefIsOpaque(imageRef) ? (kCGImageAlphaNoneSkipFirst | kCGBitmapByteOrder32Host) : (kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrder32Host);
    CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceRGB();
    
    //Use UIGraphicsBeginImageContext parameters from docs: https://developer.apple.com/library/ios/documentation/UIKit/Reference/UIKitFunctionReference/#//apple_ref/c/func/UIGraphicsBeginImageContextWithOptions
    CGContextRef ctx = CGBitmapContextCreate(NULL, imageSize.width, imageSize.height,
                                             8,
                                             0,
                                             colorspace,
                                             info);
    
    CGColorSpaceRelease(colorspace);
    
    if (ctx) {
        CGContextSetBlendMode(ctx, kCGBlendModeCopy);
        CGContextDrawImage(ctx, CGRectMake(0, 0, imageSize.width, imageSize.height), imageRef);
        
        CGImageRef decodedImageRef = CGBitmapContextCreateImage(ctx);
        if (decodedImageRef) {
            CFAutorelease(decodedImageRef);
        }
        CGContextRelease(ctx);
        return decodedImageRef;
        
    }
    
    return imageRef;
}

#if PIN_TARGET_IOS
UIImageOrientation pin_UIImageOrientationFromImageSource(CGImageSourceRef imageSourceRef) {
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
