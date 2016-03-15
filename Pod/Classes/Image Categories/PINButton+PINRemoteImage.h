//
//  UIButton+PINRemoteImage.h
//  Pods
//
//  Created by Garrett Moon on 8/18/14.
//
//

#if (TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR || TARGET_OS_TV)
@import UIKit;
#elif TARGET_OS_MAC
@import Cocoa;
#endif

#import "PINRemoteImageManager.h"
#import "PINRemoteImageCategoryManager.h"

@interface PINButton (PINRemoteImage) <PINRemoteImageCategory>

@end
