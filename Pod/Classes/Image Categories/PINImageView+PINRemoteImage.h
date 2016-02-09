//
//  UIImageView+PINRemoteImage.h
//  Pods
//
//  Created by Garrett Moon on 8/17/14.
//
//

#ifdef __IPHONE_OS_VERSION_MIN_REQUIRED
#import <UIKit/UIKit.h>
#else
#import <Cocoa/Cocoa.h>
#endif

#import "PINRemoteImageManager.h"
#import "PINRemoteImageCategoryManager.h"

@interface PINImageView (PINRemoteImage) <PINRemoteImageCategory>

@end
