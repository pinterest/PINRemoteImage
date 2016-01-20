//
//  UIImage+DecodedImage.h
//  Pods
//
//  Created by Garrett Moon on 11/19/14.
//
//

#import <UIKit/UIKit.h>

@interface UIImage (PINDecodedImage)

+ (UIImage *)pin_decodedImageWithData:(NSData *)data;
+ (UIImage *)pin_decodedImageWithData:(NSData *)data skipDecodeIfPossible:(BOOL)skipDecodeIfPossible;
+ (UIImage *)pin_decodedImageWithCGImageRef:(CGImageRef)imageRef;
+ (UIImage *)pin_decodedImageWithCGImageRef:(CGImageRef)imageRef orientation:(UIImageOrientation) orientation;

@end

@interface UIImage (PINDecodedImage_Deprecated)

+ (UIImage *)decodedImageWithData:(NSData *)data __attribute((deprecated("use pin_decodedImageWithData:")));
+ (UIImage *)decodedImageWithData:(NSData *)data skipDecodeIfPossible:(BOOL)skipDecodeIfPossible __attribute((deprecated("use pin_decodedImageWithData:skipDecodeIfPossible:")));
+ (UIImage *)decodedImageWithCGImageRef:(CGImageRef)imageRef __attribute((deprecated("use pin_decodedImageWithCGImageRef:")));

@end
