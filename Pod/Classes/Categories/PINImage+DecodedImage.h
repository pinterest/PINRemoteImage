//
//  UIImage+DecodedImage.h
//  Pods
//
//  Created by Garrett Moon on 11/19/14.
//
//

#ifdef __IPHONE_OS_VERSION_MIN_REQUIRED
#import <UIKit/UIKit.h>
#else
#import <Cocoa/Cocoa.h>
#endif

#import "PINRemoteImageMacros.h"

#ifdef __MAC_OS_X_VERSION_MIN_REQUIRED
@interface NSImage (PINiOSMapping)

@property(nonatomic, readonly) CGImageRef CGImage;

+ (NSImage *)imageWithData:(NSData *)imageData;
+ (NSImage *)imageWithContentsOfFile:(NSString *)path;
+ (NSImage *)imageWithCGImage:(CGImageRef)imageRef;

@end
#endif

NSData *PINImageJPEGRepresentation(PINImage *image, CGFloat compressionQuality);
NSData *PINImagePNGRepresentation(PINImage *image);

@interface PINImage (PINDecodedImage)

+ (PINImage *)pin_decodedImageWithData:(NSData *)data;
+ (PINImage *)pin_decodedImageWithData:(NSData *)data skipDecodeIfPossible:(BOOL)skipDecodeIfPossible;
+ (PINImage *)pin_decodedImageWithCGImageRef:(CGImageRef)imageRef;
#ifdef __IPHONE_OS_VERSION_MIN_REQUIRED
+ (PINImage *)pin_decodedImageWithCGImageRef:(CGImageRef)imageRef orientation:(UIImageOrientation) orientation;
#endif

@end

@interface PINImage (PINDecodedImage_Deprecated)

+ (PINImage *)decodedImageWithData:(NSData *)data __attribute((deprecated("use pin_decodedImageWithData:")));
+ (PINImage *)decodedImageWithData:(NSData *)data skipDecodeIfPossible:(BOOL)skipDecodeIfPossible __attribute((deprecated("use pin_decodedImageWithData:skipDecodeIfPossible:")));
+ (PINImage *)decodedImageWithCGImageRef:(CGImageRef)imageRef __attribute((deprecated("use pin_decodedImageWithCGImageRef:")));

@end
