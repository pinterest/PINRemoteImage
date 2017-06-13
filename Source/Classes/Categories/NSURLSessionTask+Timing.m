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

static NSString * const kPINURLSessionTaskStateKey = @"state";

@interface PINURLSessionTaskObserver : NSObject

@property (atomic, assign) CFTimeInterval startTime;
@property (atomic, assign) CFTimeInterval endTime;

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithTask:(NSURLSessionTask *)task NS_DESIGNATED_INITIALIZER;

@end

@implementation PINURLSessionTaskObserver

- (instancetype)initWithTask:(NSURLSessionTask *)task
{
    if (self = [super init]) {
        _startTime = 0;
        _endTime = 0;
        [task addObserver:self forKeyPath:kPINURLSessionTaskStateKey options:0 context:nil];
    }
    return self;
}

- (void)removeObservers:(NSURLSessionTask *)task
{
    [task removeObserver:self forKeyPath:kPINURLSessionTaskStateKey];
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
    NSURLSessionTask *task = (NSURLSessionTask *)object;
    if ([keyPath isEqualToString:kPINURLSessionTaskStateKey]) {
        switch (task.state) {
            case NSURLSessionTaskStateRunning:
                if (self.startTime == 0) {
                    self.startTime = CACurrentMediaTime();
                }
                break;
                
            case NSURLSessionTaskStateCompleted:
                // Don't set endTime if task was never started.
                if (self.startTime > 0 && self.endTime == 0) {
                    self.endTime = CACurrentMediaTime();
                }
                break;
                
            default:
                break;
        }
    }
}

@end

@implementation NSURLSessionTask (Additions)

- (void)PIN_setupSessionTaskObserver
{
    // It's necessary to swizzle dealloc here to remove the observer :(
    // I wasn't able to figure out another way; kvo assertion about observed objects being observed occurs
    // *before* associated objects are dealloc'd
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        SEL deallocSelector = NSSelectorFromString(@"dealloc");
        Method deallocMethod = class_getInstanceMethod([NSURLSessionTask class], deallocSelector);
        IMP originalImplementation = method_getImplementation(deallocMethod);
        IMP newImplementation = imp_implementationWithBlock(^(void *obj){
            @autoreleasepool {
                //remove state observer
                PINURLSessionTaskObserver *observer = objc_getAssociatedObject((__bridge id)obj, @selector(PIN_setupSessionTaskObserver));
                if (observer) {
                    [observer removeObservers:(__bridge NSURLSessionTask *)obj];
                }
            }
            
            //casting original implementation is necessary to ensure ARC doesn't attempt to retain during dealloc
            ((void (*)(void *, SEL))originalImplementation)(obj, deallocSelector);
        });
        class_replaceMethod([NSURLSessionTask class], deallocSelector, newImplementation, method_getTypeEncoding(deallocMethod));
    });
    
    PINURLSessionTaskObserver *observer = [[PINURLSessionTaskObserver alloc] initWithTask:self];
    objc_setAssociatedObject(self, @selector(PIN_setupSessionTaskObserver), observer, OBJC_ASSOCIATION_RETAIN);
}

- (CFTimeInterval)PIN_startTime
{
    PINURLSessionTaskObserver *observer = objc_getAssociatedObject(self, @selector(PIN_setupSessionTaskObserver));
    NSAssert(observer != nil, @"setupSessionTaskObserver should have been called before.");
    if (observer == nil) {
        return 0;
    }
    return observer.startTime;
}

- (CFTimeInterval)PIN_endTime
{
    PINURLSessionTaskObserver *observer = objc_getAssociatedObject(self, @selector(PIN_setupSessionTaskObserver));
    NSAssert(observer != nil, @"setupSessionTaskObserver should have been called before.");
    if (observer == nil) {
        return 0;
    }
    return observer.endTime;
}

@end
