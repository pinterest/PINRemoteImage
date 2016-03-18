//
//  UIImageView+PINRemoteImage.h
//  Pods
//
//  Created by Garrett Moon on 8/17/14.
//
//

#if PIN_TARGET_IOS
@import UIKit;
#elif PIN_TARGET_MAC
@import Cocoa;
#endif

#import "PINRemoteImageManager.h"
#import "PINRemoteImageCategoryManager.h"

@interface PINImageView (PINRemoteImage) <PINRemoteImageCategory>

@end
