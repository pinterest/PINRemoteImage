//
//  Oriented.h
//  Example
//
//  Created by Alex Quinlivan on 16/04/21.
//  Copyright © 2021 Garrett Moon. All rights reserved.
//

#import <Foundation/Foundation.h>

#ifdef __IPHONE_OS_VERSION_MIN_REQUIRED
#import <UIKit/UIKit.h>
#else
#import <Cocoa/Cocoa.h>
#endif

#import "ImageSource.h"

NS_ASSUME_NONNULL_BEGIN

@interface Oriented : NSObject <ImageSource>

@end

NS_ASSUME_NONNULL_END
