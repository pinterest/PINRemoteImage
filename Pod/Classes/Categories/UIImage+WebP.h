//
//  UIImage+WebP.h
//  Pods
//
//  Created by Garrett Moon on 11/18/14.
//
//

#ifdef PIN_WEBP

#import <UIKit/UIKit.h>

@interface UIImage (PINWebP)

+ (UIImage *)pin_imageWithWebPData:(NSData *)webPData;

@end

@interface UIImage (PINWebP_Deprecated)

+ (UIImage *)imageWithWebPData:(NSData *)webPData __attribute((deprecated("use pin_imageWithWebPData:")));

@end
#endif
