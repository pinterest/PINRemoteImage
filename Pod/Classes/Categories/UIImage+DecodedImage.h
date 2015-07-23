//
//  UIImage+DecodedImage.h
//  Pods
//
//  Created by Garrett Moon on 11/19/14.
//
//

@import UIKit;

@interface UIImage (DecodedImage)

+ (UIImage *)decodedImageWithData:(NSData *)data;
+ (UIImage *)decodedImageWithData:(NSData *)data skipDecodeIfPossible:(BOOL)skipDecodeIfPossible;
+ (UIImage *)decodedImageWithCGImageRef:(CGImageRef)imageRef;

@end
