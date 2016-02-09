//
//  UIImage+WebP.h
//  Pods
//
//  Created by Garrett Moon on 11/18/14.
//
//

#ifdef PIN_WEBP

#ifdef __IPHONE_OS_VERSION_MIN_REQUIRED
#import <UIKit/UIKit.h>
#else
#import <Cocoa/Cocoa.h>
#endif

#import "PINRemoteImageMacros.h"

@interface PINImage (PINWebP)

+ (PINImage *)pin_imageWithWebPData:(NSData *)webPData;

@end

#endif
