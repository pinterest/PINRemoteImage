//
//  UIImage+DecodedImage.h
//  Pods
//
//  Created by Garrett Moon on 11/19/14.
//
//

#import <UIKit/UIKit.h>

@interface UIImage (PINDecodedImage)

+ (nullable UIImage *)pin_decodedImageWithData:(nonnull NSData *)data;
+ (nullable UIImage *)pin_decodedImageWithData:(nonnull NSData *)data skipDecodeIfPossible:(BOOL)skipDecodeIfPossible;
+ (nullable UIImage *)pin_decodedImageWithCGImageRef:(nonnull CGImageRef)imageRef;
+ (nullable UIImage *)pin_decodedImageWithCGImageRef:(nonnull CGImageRef)imageRef orientation:(UIImageOrientation) orientation;

@end

@interface UIImage (PINDecodedImage_Deprecated)

+ (nullable UIImage *)decodedImageWithData:(nullable NSData *)data __attribute((deprecated("use pin_decodedImageWithData:")));
+ (nullable UIImage *)decodedImageWithData:(nullable NSData *)data skipDecodeIfPossible:(BOOL)skipDecodeIfPossible __attribute((deprecated("use pin_decodedImageWithData:skipDecodeIfPossible:")));
+ (nullable UIImage *)decodedImageWithCGImageRef:(nonnull CGImageRef)imageRef __attribute((deprecated("use pin_decodedImageWithCGImageRef:")));

@end
