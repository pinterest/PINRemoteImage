//
//  NSURLSessionTask+Timing.m
//  PINRemoteImage
//
//  Created by Garrett Moon on 5/19/17.
//  Copyright © 2017 Pinterest. All rights reserved.
//

#import "NSURLSessionTask+Timing.h"

#import <objc/runtime.h>
#import <QuartzCore/QuartzCore.h>

@implementation NSURLSessionTask (Additions)

- (void)PIN_updateStartTime
{
    CFTimeInterval PIN_startTime = [self PIN_startTime];
    if (PIN_startTime == 0) {
        self.PIN_startTime = CACurrentMediaTime();
    }
}

- (void)PIN_updateEndTime
{
    // Don't set endTime if task was never started.
    if (self.PIN_startTime > 0 && self.PIN_endTime == 0) {
        self.PIN_endTime = CACurrentMediaTime();
    }
}

- (CFTimeInterval)PIN_startTime
{
    return [objc_getAssociatedObject(self, @selector(PIN_startTime)) doubleValue];
}

- (void)setPIN_startTime:(CFTimeInterval)PIN_startTime
{
    objc_setAssociatedObject(self, @selector(PIN_startTime), @(PIN_startTime), OBJC_ASSOCIATION_COPY);
}

- (CFTimeInterval)PIN_endTime
{
    return [objc_getAssociatedObject(self, @selector(PIN_endTime)) doubleValue];
}

- (void)setPIN_endTime:(CFTimeInterval)PIN_endTime
{
    objc_setAssociatedObject(self, @selector(PIN_endTime), @(PIN_endTime), OBJC_ASSOCIATION_COPY);
}

@end
