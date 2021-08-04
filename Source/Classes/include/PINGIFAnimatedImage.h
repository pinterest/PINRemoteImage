//
//  PINGIFAnimatedImage.h
//  PINRemoteImage
//
//  Created by Garrett Moon on 9/17/17.
//  Copyright © 2017 Pinterest. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "PINAnimatedImage.h"

@interface PINGIFAnimatedImage : PINAnimatedImage <PINAnimatedImage>

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithAnimatedImageData:(NSData *)animatedImageData NS_DESIGNATED_INITIALIZER;

@end
