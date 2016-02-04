//
//  UIImage+WebP.h
//  Pods
//
//  Created by Garrett Moon on 11/18/14.
//
//

#if __has_include(<webp/decode.h>)

#ifdef __IPHONE_OS_VERSION_MIN_REQUIRED
#import <UIKit/UIKit.h>
#else
#import <Cocoa/Cocoa.h>
#endif

#import "PINRemoteImageMacros.h"

@interface PINImage (PINWebP)

+ (PINImage *)pin_imageWithWebPData:(NSData *)webPData;

@end

@interface PINImage (PINWebP_Deprecated)

+ (PINImage *)imageWithWebPData:(NSData *)webPData __attribute((deprecated("use pin_imageWithWebPData:")));

@end
#endif
