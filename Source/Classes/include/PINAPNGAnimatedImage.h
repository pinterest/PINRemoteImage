//
//  PINAPNGAnimatedImage.h
//  PINRemoteImage
//
//  Created by SAGESSE on 2020/2/28.
//  Copyright © 2020 Pinterest. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

#import "PINAnimatedImage.h"

@interface PINAPNGAnimatedImage : PINAnimatedImage <PINAnimatedImage>

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithAnimatedImageData:(NSData *)animatedImageData NS_DESIGNATED_INITIALIZER;

@end

