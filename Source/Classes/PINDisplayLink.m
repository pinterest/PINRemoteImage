//
//  PINDisplayLink.m
//  Pods
//
//  Created by Garrett Moon on 4/23/18.
//

#import "PINDisplayLink.h"

#if PIN_TARGET_MAC

@interface PINDisplayLink ()

@property (nonatomic, readonly) id target;
@property (nonatomic, readonly) SEL selector;
@property (nonatomic, readonly) NSRunLoop *runloop;
@property (nonatomic, readonly) NSRunLoopMode mode;

- (void)displayLinkFiredWithDuration:(CFTimeInterval)duration;

@end

static CVReturn displayLinkFired (CVDisplayLinkRef displayLink,
                                  const CVTimeStamp *inNow,
                                  const CVTimeStamp *inOutputTime,
                                  CVOptionFlags flagsIn,
                                  CVOptionFlags *flagsOut,
                                  void *displayLinkContext)
{
    CFTimeInterval duration = inOutputTime->videoRefreshPeriod / (inOutputTime->videoTimeScale * inOutputTime->rateScalar);
    PINDisplayLink *link = (__bridge PINDisplayLink *)displayLinkContext;
    [link displayLinkFiredWithDuration:duration];
    return kCVReturnSuccess;
}

@implementation PINDisplayLink
{
    CVDisplayLinkRef _displayLinkRef;
    
    BOOL _paused;
    NSInteger _frameInterval;
    CFTimeInterval _duration;
}

+ (PINDisplayLink *)displayLinkWithTarget:(id)target selector:(SEL)sel
{
    return [[PINDisplayLink alloc] initWithTarget:target selector:sel];
}

- (PINDisplayLink *)initWithTarget:(id)target selector:(SEL)sel
{
    if (self = [super init]) {
        _target = target;
        _selector = sel;
        CVDisplayLinkCreateWithActiveCGDisplays(&_displayLinkRef);
        CVDisplayLinkSetOutputCallback(_displayLinkRef, &displayLinkFired, (__bridge void * _Nullable)(self));
    }
    return self;
}

- (void)dealloc
{
    if (_displayLinkRef) {
        CVDisplayLinkRelease(_displayLinkRef);
    }
}

- (void)displayLinkFiredWithDuration:(CFTimeInterval)duration
{
    dispatch_async(dispatch_get_main_queue(), ^{
        self.duration = duration;
        [self.runloop performSelector:self.selector target:self.target argument:self order:NSUIntegerMax modes:@[self.mode]];
    });
}

- (void)addToRunLoop:(NSRunLoop *)runloop forMode:(NSRunLoopMode)mode
{
    PINAssertMain();
    NSAssert(runloop && mode, @"Must set a runloop and a mode.");
    _runloop = runloop;
    _mode = mode;
    if (_paused == NO) {
        CVDisplayLinkStart(_displayLinkRef);
    }
}

- (void)removeFromRunLoop:(NSRunLoop *)runloop forMode:(NSRunLoopMode)mode
{
    _runloop = nil;
    _mode = nil;
    if (_paused == NO) {
        CVDisplayLinkStop(_displayLinkRef);
    }
}

- (BOOL)isPaused
{
    PINAssertMain();
    return _paused;
}

- (void)setPaused:(BOOL)paused
{
    PINAssertMain();
    if (_paused == paused) {
        return;
    }
    
    _paused = paused;
    if (paused) {
        CVDisplayLinkStop(_displayLinkRef);
    } else {
        CVDisplayLinkStart(_displayLinkRef);
    }
}

- (CFTimeInterval)duration
{
    PINAssertMain();
    return _duration;
}

- (void)setDuration:(CFTimeInterval)duration
{
    PINAssertMain();
    _duration = duration;
}

- (NSInteger)frameInterval
{
    PINAssertMain();
    return _frameInterval;
}

- (void)setFrameInterval:(NSInteger)frameInterval
{
    PINAssertMain();
    _frameInterval = frameInterval;
}

@end
#endif
