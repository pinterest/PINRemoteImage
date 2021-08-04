//
//  PINAnimatedImage+PINAnimatedImageTesting.h
//  PINRemoteImageTests
//
//  Created by Garrett Moon on 10/16/17.
//  Copyright © 2017 Pinterest. All rights reserved.
//

#import <PINRemoteImage/PINRemoteImage.h>
#import <PINRemoteImage/PINAnimatedImageView.h>

@interface PINAnimatedImage (PINAnimatedImageTesting)

+ (NSUInteger)greatestCommonDivisorOfA:(NSUInteger)a andB:(NSUInteger)b;

@end

@interface PINAnimatedImageView (PINAnimatedImageViewTesting)

- (NSUInteger)frameIndexAtPlayHeadPosition:(CFTimeInterval)playHead;

@end
