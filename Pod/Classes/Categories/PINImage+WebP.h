//
//  UIImage+WebP.h
//  Pods
//
//  Created by Garrett Moon on 11/18/14.
//
//

#ifdef PIN_WEBP

#if TARGET_OS_IPHONE || TARGET_OS_TV
#import <UIKit/UIKit.h>
#elif TARGET_OS_MAC
#import <Cocoa/Cocoa.h>
#endif

#import "PINRemoteImageMacros.h"

@interface PINImage (PINWebP)

+ (PINImage *)pin_imageWithWebPData:(NSData *)webPData;

@end

#endif
