//
//  UIImage+WebP.h
//  Pods
//
//  Created by Garrett Moon on 11/18/14.
//
//

#import "PINRemoteImageMacros.h"

#if PIN_WEBP

#if PIN_TARGET_IOS
#import <UIKit/UIKit.h>
#elif PIN_TARGET_MAC
#import <Cocoa/Cocoa.h>
#endif

@interface PINImage (PINWebP)

+ (PINImage *)pin_imageWithWebPData:(NSData *)webPData;

@end

#endif
