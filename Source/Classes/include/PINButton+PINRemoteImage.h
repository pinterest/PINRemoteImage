//
//  UIButton+PINRemoteImage.h
//  Pods
//
//  Created by Garrett Moon on 8/18/14.
//
//

#import "Source/Classes/include/PINRemoteImageMacros.h"

#if PIN_TARGET_IOS
#import <UIKit/UIKit.h>
#elif PIN_TARGET_MAC
#import <Cocoa/Cocoa.h>
#endif

#import "Source/Classes/include/PINRemoteImageManager.h"
#import "Source/Classes/include/PINRemoteImageCategoryManager.h"

@interface PINButton (PINRemoteImage) <PINRemoteImageCategory>

@end
