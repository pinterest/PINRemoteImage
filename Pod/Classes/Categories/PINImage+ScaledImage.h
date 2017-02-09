//
//  UIImage+ScaledImage.h
//  Pods
//
//  Created by Michael Schneider on 2/9/17.
//
//

#import <Foundation/Foundation.h>

#if PIN_TARGET_IOS
#import <UIKit/UIKit.h>
#elif PIN_TARGET_MAC
#import <Cocoa/Cocoa.h>
#endif

#import "PINRemoteImageMacros.h"

@interface PINImage (PINScaledImage)

- (PINImage *)pin_scaledImageForKey:(NSString *)key;
+ (PINImage *)pin_scaledImageForImage:(PINImage *)image withKey:(NSString *)key;

@end
