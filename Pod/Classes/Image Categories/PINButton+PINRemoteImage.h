//
//  UIButton+PINRemoteImage.h
//  Pods
//
//  Created by Garrett Moon on 8/18/14.
//
//

#if TARGET_OS_IPHONE || TARGET_OS_TV
#import <UIKit/UIKit.h>
#elif TARGET_OS_MAC
#import <Cocoa/Cocoa.h>
#endif

#import "PINRemoteImageManager.h"
#import "PINRemoteImageCategoryManager.h"

@interface PINButton (PINRemoteImage) <PINRemoteImageCategory>

@end
