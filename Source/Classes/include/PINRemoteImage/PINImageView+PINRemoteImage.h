//
//  UIImageView+PINRemoteImage.h
//  Pods
//
//  Created by Garrett Moon on 8/17/14.
//
//

#import <PINRemoteImage/PINRemoteImageMacros.h>

#if PIN_TARGET_IOS
#import <UIKit/UIKit.h>
#elif PIN_TARGET_MAC
#import <Cocoa/Cocoa.h>
#endif

#import <PINRemoteImage/PINRemoteImageManager.h>
#import <PINRemoteImage/PINRemoteImageCategoryManager.h>

@interface PINImageView (PINRemoteImage) <PINRemoteImageCategory>

@end
