//
//  PINProgressiveImage+Accelerate.h
//  PINRemoteImage
//
//  Created by Adlai Holler on 5/23/16.
//  Copyright © 2016 Garrett Moon. All rights reserved.
//

#import "PINRemoteImageMacros.h"
#import <PINRemoteImage/PINProgressiveImage.h>

/**
 An implementation of gaussian blur using accelerate rather than CoreImage, 
 provided here so we can do performance testing without adding Accelerate into the
 public framework.
 */
@interface PINProgressiveImage (Accelerate)

+ (PINImage *)postProcessImageUsingAccelerate:(PINImage *)inputImage withProgress:(float)progress;

@end
