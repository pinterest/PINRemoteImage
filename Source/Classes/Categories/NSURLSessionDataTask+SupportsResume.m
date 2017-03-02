//
//  NSURLSessionDataTask+SupportsResume.m
//  PINRemoteImage
//
//  Created by Garrett Moon on 3/1/17.
//  Copyright © 2017 Pinterest. All rights reserved.
//

#import "NSURLSessionDataTask+SupportsResume.h"

#import <objc/runtime.h>

NSString * const PINDataTaskSupportsResume = @"PINDataTaskSupportsResume";

@implementation NSURLSessionDataTask (SupportsResume)

- (BOOL)supportsResume
{
    NSNumber *supportsResume = objc_getAssociatedObject(self, (__bridge const void *)PINDataTaskSupportsResume);
    return [supportsResume boolValue];
}

- (void)setSupportsResume:(BOOL)supportsResume
{
    objc_setAssociatedObject(self, (__bridge const void *)PINDataTaskSupportsResume, [NSNumber numberWithBool:YES], OBJC_ASSOCIATION_RETAIN);
}

@end
