//
//  TestAnimatedImage.m
//  PINRemoteImage
//
//  Created by Greg Bolsinga on 3/10/20.
//  Copyright © 2020 Pinterest. All rights reserved.
//

#import "TestAnimatedImage.h"

@implementation TestAnimatedImage

@synthesize bytesPerFrame;

@synthesize data;

@synthesize error;

@synthesize frameCount;

@synthesize frameInterval;

@synthesize height;

@synthesize loopCount;

@synthesize totalDuration;

@synthesize width;

- (CFTimeInterval)durationAtIndex:(NSUInteger)index {
    return 0;
}

- (nullable CGImageRef)imageAtIndex:(NSUInteger)index cacheProvider:(nullable id<PINCachedAnimatedFrameProvider>)cacheProvider {
    return nil;
}

@end
