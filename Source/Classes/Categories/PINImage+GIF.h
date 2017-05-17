//
//  PINImage+GIF.h
//  PINRemoteImage
//
//  Created by ganzy on 2017/04/22.
//  Copyright © 2017 Pinterest. All rights reserved.
//

#if PIN_TARGET_IOS
#import <UIKit/UIKit.h>
#elif PIN_TARGET_MAC
#import <Cocoa/Cocoa.h>
#endif

#import "PINRemoteImageMacros.h"

@interface PINImage (GIF)

+ (PINImage *)pin_imageWithGIFData:(NSData *)gifData;

@end
