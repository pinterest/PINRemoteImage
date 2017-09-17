//
//  PINAnimatedImage.m
//  PINRemoteImage
//
//  Created by Garrett Moon on 9/17/17.
//  Copyright © 2017 Pinterest. All rights reserved.
//

#import "PINAnimatedImage.h"

NSString *kPINAnimatedImageErrorDomain = @"kPINAnimatedImageErrorDomain";

const NSTimeInterval kPINAnimatedImageDisplayRefreshRate = 60.0;
//http://nullsleep.tumblr.com/post/16524517190/animated-gif-minimum-frame-delay-browser
const Float32 kPINAnimatedImageMinimumDuration = 1 / kPINAnimatedImageDisplayRefreshRate;
const Float32 kPINAnimatedImageDefaultDuration = 0.1;

@interface PINAnimatedImage ()
{
    CFTimeInterval _totalDuration;
}
@end

@implementation PINAnimatedImage

- (instancetype)init
{
    if (self = [super init]) {
        _totalDuration = -1;
    }
    return self;
}

- (CFTimeInterval)durationAtIndex:(NSUInteger)index
{
    NSAssert(NO, @"Must be overridden by subclass");
    return 0;
}

- (size_t)frameCount
{
    NSAssert(NO, @"Must be overridden by subclass");
    return 0;
}


- (CFTimeInterval)totalDuration
{
    if (_totalDuration == -1) {
        _totalDuration = 0;
        for (NSUInteger idx = 0; idx < self.frameCount; idx++) {
            _totalDuration += [self durationAtIndex:idx];
        }
    }

    return _totalDuration;
}

- (NSUInteger)frameInterval
{
    return MAX(self.minimumFrameInterval * kPINAnimatedImageDisplayRefreshRate, 1);
}

//Credit to FLAnimatedImage ( https://github.com/Flipboard/FLAnimatedImage ) for display link interval calculations
- (NSTimeInterval)minimumFrameInterval
{
    const NSTimeInterval kGreatestCommonDivisorPrecision = 2.0 / kPINAnimatedImageMinimumDuration;
    
    // Scales the frame delays by `kGreatestCommonDivisorPrecision`
    // then converts it to an UInteger for in order to calculate the GCD.
    NSUInteger scaledGCD = lrint([self durationAtIndex:0] * kGreatestCommonDivisorPrecision);
    for (NSUInteger durationIdx = 0; durationIdx < self.frameCount; durationIdx++) {
        Float32 duration = [self durationAtIndex:durationIdx];
        scaledGCD = gcd(lrint(duration * kGreatestCommonDivisorPrecision), scaledGCD);
    }
    
    // Reverse to scale to get the value back into seconds.
    return (scaledGCD / kGreatestCommonDivisorPrecision);
}

//Credit to FLAnimatedImage ( https://github.com/Flipboard/FLAnimatedImage ) for display link interval calculations
static NSUInteger gcd(NSUInteger a, NSUInteger b)
{
    // http://en.wikipedia.org/wiki/Greatest_common_divisor
    if (a < b) {
        return gcd(b, a);
    } else if (a == b) {
        return b;
    }
    
    while (true) {
        NSUInteger remainder = a % b;
        if (remainder == 0) {
            return b;
        }
        a = b;
        b = remainder;
    }
}

@end
