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

@property(nonatomic, readonly, nullable) CGImageRef CGImage;

+ (nullable NSImage *)imageWithData:(nonnull NSData *)imageData;
+ (nullable NSImage *)imageWithContentsOfFile:(nonnull NSString *)path;
+ (nonnull NSImage *)imageWithCGImage:(nonnull CGImageRef)imageRef;

@end
#endif

NSData * __nullable PINImageJPEGRepresentation(PINImage * __nonnull image, CGFloat compressionQuality);
NSData * __nullable PINImagePNGRepresentation(PINImage * __nonnull image);

@interface PINImage (PINDecodedImage)

+ (nullable PINImage *)pin_decodedImageWithData:(nonnull NSData *)data;
+ (nullable PINImage *)pin_decodedImageWithData:(nonnull NSData *)data skipDecodeIfPossible:(BOOL)skipDecodeIfPossible;
+ (nullable PINImage *)pin_decodedImageWithCGImageRef:(nonnull CGImageRef)imageRef;
#ifdef __IPHONE_OS_VERSION_MIN_REQUIRED
+ (nullable PINImage *)pin_decodedImageWithCGImageRef:(nonnull CGImageRef)imageRef orientation:(UIImageOrientation) orientation;
#endif

@end
