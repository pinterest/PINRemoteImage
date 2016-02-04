//
//  Kitten.h
//  PINRemoteImage
//
//  Created by Michael Schneider on 1/6/16.
//  Copyright © 2016 mischneider. All rights reserved.
//

#ifdef __IPHONE_OS_VERSION_MIN_REQUIRED
#import <UIKit/UIKit.h>
#else
#import <Cocoa/Cocoa.h>
#endif

@interface Kitten : NSObject

@property (nonatomic, strong) NSURL *imageURL;
@property (nonatomic, strong) id dominantColor;
@property (nonatomic, assign) CGSize imageSize;

+ (void)fetchKittenForWidth:(CGFloat)width completion:(void (^)(NSArray *kittens))completion;

@end
