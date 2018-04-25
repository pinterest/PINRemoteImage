//
//  PINRemoteWeakProxy.m
//  PINRemoteImage
//
//  Created by Garrett Moon on 4/24/18.
//  Copyright © 2018 Pinterest. All rights reserved.
//

#import "PINRemoteWeakProxy.h"

@interface PINRemoteWeakProxy ()
{
    __weak id _target;
    Class _targetClass;
}
@end

@implementation PINRemoteWeakProxy

+ (PINRemoteWeakProxy *)weakProxyWithTarget:(id)target
{
    return [[PINRemoteWeakProxy alloc] initWithTarget:target];
}

- (instancetype)initWithTarget:(id)target
{
    if (self) {
        _target = target;
        _targetClass = [target class];
    }
    return self;
}

- (BOOL)respondsToSelector:(SEL)aSelector
{
    return [_target respondsToSelector:aSelector];
}

- (BOOL)conformsToProtocol:(Protocol *)aProtocol
{
    return [_target conformsToProtocol:aProtocol];
}

- (id)forwardingTargetForSelector:(SEL)aSelector
{
    return _target;
}

- (void)forwardInvocation:(NSInvocation *)invocation
{
    // Drop it since we shouldn't get here if _target is nil
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)sel
{
    return _target ? [_target methodSignatureForSelector:sel] : [_targetClass instanceMethodSignatureForSelector:sel];
}

@end
