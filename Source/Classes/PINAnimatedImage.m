//
//  PINAnimatedImage.m
//  PINRemoteImage
//
//  Created by Garrett Moon on 9/17/17.
//  Copyright © 2017 Pinterest. All rights reserved.
//

#import "PINAnimatedImage.h"

NSErrorDomain const kPINAnimatedImageErrorDomain = @"kPINAnimatedImageErrorDomain";

//http://nullsleep.tumblr.com/post/16524517190/animated-gif-minimum-frame-delay-browser
const Float32 kPINAnimatedImageDefaultDuration = 0.1;

@interface PINAnimatedImage ()
{
    CFTimeInterval _totalDuration;
}
@end

@implementation PINAnimatedImage

+ (NSInteger)maximumFramesPerSecond
{
    static dispatch_once_t onceToken;
    static NSInteger maximumFramesPerSecond = 60;
    
    dispatch_once(&onceToken, ^{
#if PIN_TARGET_IOS
        if (@available(iOS 10.3, tvOS 10.3, *)) {
            maximumFramesPerSecond = 0;
            for (UIScreen *screen in [UIScreen screens]) {
                if ([screen maximumFramesPerSecond] > maximumFramesPerSecond) {
                    maximumFramesPerSecond = [screen maximumFramesPerSecond];
                }
            }
        }
#endif
    });
    return maximumFramesPerSecond;
}

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
    return MAX(self.minimumFrameInterval * [PINAnimatedImage maximumFramesPerSecond], 1);
}

//Credit to FLAnimatedImage ( https://github.com/Flipboard/FLAnimatedImage ) for display link interval calculations
- (NSTimeInterval)minimumFrameInterval
{
    static dispatch_once_t onceToken;
    static NSTimeInterval kGreatestCommonDivisorPrecision;
    dispatch_once(&onceToken, ^{
        kGreatestCommonDivisorPrecision = 2.0 / (1.0 / [PINAnimatedImage maximumFramesPerSecond]);
    });
    
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

// This likely isn't the most efficient but it's easy to reason about and we don't call it
// with super large numbers.
static NSUInteger gcd(NSUInteger a, NSUInteger b)
{
    // http://en.wikipedia.org/wiki/Greatest_common_divisor
    NSCAssert(a > 0 && b > 0, @"A and B must be greater than 0");
    
    while (a != b) {
        if (a > b) {
            a = a - b;
        } else {
            b = b - a;
        }
    }
    return a;
}

// Used only in testing
+ (NSUInteger)greatestCommonDivisorOfA:(NSUInteger)a andB:(NSUInteger)b
{
    return gcd(a, b);
}

@end
