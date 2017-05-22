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

@interface PINURLSessionTaskObserver : NSObject
{
    id selfCopy;
}

@property (atomic, assign) CFTimeInterval startTime;
@property (atomic, assign) CFTimeInterval endTime;
@property (nonatomic, weak, readonly) NSURLSessionTask *task;

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithTask:(NSURLSessionTask *)task NS_DESIGNATED_INITIALIZER;

@end

@implementation PINURLSessionTaskObserver

- (instancetype)initWithTask:(NSURLSessionTask *)task
{
    if (self = [super init]) {
        _task = task;
        _startTime = 0;
        _endTime = 0;
        [_task addObserver:self forKeyPath:@"state" options:0 context:nil];
    }
    return self;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
    NSURLSessionTask *task = (NSURLSessionTask *)object;
    switch (task.state) {
        case NSURLSessionTaskStateRunning:
            if (self.startTime == 0) {
                self.startTime = CACurrentMediaTime();
            }
            break;

        case NSURLSessionTaskStateCompleted:
            NSAssert(self.startTime != 0, @"Expect that task was started before it's completed.");
            if (self.endTime == 0) {
                self.endTime = CACurrentMediaTime();
            }
            break;
            
        default:
            break;
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
                [(__bridge id)obj removeObserver:observer forKeyPath:@"state"];
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
