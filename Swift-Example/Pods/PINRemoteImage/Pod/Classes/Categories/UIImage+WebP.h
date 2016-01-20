//
//  UIImage+WebP.h
//  Pods
//
//  Created by Garrett Moon on 11/18/14.
//
//

#if __has_include(<webp/decode.h>)

#import <UIKit/UIKit.h>

@interface UIImage (PINWebP)

+ (UIImage *)pin_imageWithWebPData:(NSData *)webPData;

@end

@interface UIImage (PINWebP_Deprecated)

+ (UIImage *)imageWithWebPData:(NSData *)webPData __attribute((deprecated("use pin_imageWithWebPData:")));

@end
#endif
