//
//  PINAnimatedImageView.m
//  Pods
//
//  Created by Garrett Moon on 4/17/18.
//

#import "PINAnimatedImageView.h"

#import "PINRemoteLock.h"

// TODO pull this out
@interface PINWeakProxy : NSProxy

+ (PINWeakProxy *)weakProxyWithTarget:(id)target;
- (instancetype)initWithTarget:(id)target;

@end

@interface PINAnimatedImageView ()
{
    CFTimeInterval _playHead;
    NSUInteger _playedLoops;
    NSUInteger _lastSuccessfulFrameIndex;
}

@property (nonatomic, assign) CGImageRef frameImage;
@property (nonatomic, strong) CADisplayLink *displayLink;
@property (nonatomic, assign) CFTimeInterval lastDisplayLinkFire;

@end

@implementation PINAnimatedImageView

@synthesize animatedImage = _animatedImage;
@synthesize displayLink = _displayLink;
@synthesize playbackPaused = _playbackPaused;
@synthesize animatedImageRunLoopMode = _animatedImageRunLoopMode;

- (instancetype)initWithAnimatedImage:(PINCachedAnimatedImage *)animatedImage
{
    if (self = [super initWithFrame:CGRectZero]) {
        [self commonInit:animatedImage];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:CGRectZero]) {
        [self commonInit:nil];
    }
    return self;
}

- (nullable instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder]) {
        [self commonInit:nil];
    }
    return self;
}

- (void)commonInit:(PINCachedAnimatedImage *)animatedImage
{
    _animatedImage = animatedImage;
    _animatedImageRunLoopMode = NSRunLoopCommonModes;
}

- (void)dealloc
{
    if (_frameImage) {
        CGImageRelease(_frameImage);
    }
}

#pragma mark - Public

- (void)setAnimatedImage:(PINCachedAnimatedImage *)animatedImage
{
    PINAssertMain();
    if (_animatedImage == animatedImage) {
        return;
    }
    
    PINCachedAnimatedImage *previousAnimatedImage = _animatedImage;
    
    _animatedImage = animatedImage;
    
    if (animatedImage != nil) {
        PINWeakify(self);
        animatedImage.coverImageReadyCallback = ^(UIImage *coverImage) {
            dispatch_async(dispatch_get_main_queue(), ^{
                PINStrongify(self);
                // In this case the lock is already gone we have to call the unlocked version therefore
                [self coverImageCompleted:coverImage];
            });
        };
        
        animatedImage.playbackReadyCallback = ^{
            dispatch_async(dispatch_get_main_queue(), ^{
                // In this case the lock is already gone we have to call the unlocked version therefore
                PINStrongify(self);
                [self checkIfShouldAnimate];
            });
        };
        if (animatedImage.playbackReady) {
            [self checkIfShouldAnimate];
        }
    } else {
        // Clean up after ourselves.
        self.layer.contents = nil;
        [self setCoverImage:nil];
    }
    
    // Animated Image can take a while to dealloc, let's try and do it off main.
    __block PINCachedAnimatedImage *strongAnimatedImage = previousAnimatedImage;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        strongAnimatedImage = nil;
    });
}

- (PINCachedAnimatedImage *)animatedImage
{
    PINAssertMain();
    return _animatedImage;
}

- (NSString *)animatedImageRunLoopMode
{
    PINAssertMain();
    return _animatedImageRunLoopMode;
}

- (void)setAnimatedImageRunLoopMode:(NSString *)newRunLoopMode
{
    PINAssertMain();
    
    NSString *runLoopMode = newRunLoopMode ?: NSRunLoopCommonModes;
    
    if (_displayLink != nil) {
        [_displayLink removeFromRunLoop:[NSRunLoop mainRunLoop] forMode:_animatedImageRunLoopMode];
        [_displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:runLoopMode];
    }
    _animatedImageRunLoopMode = runLoopMode;
}

- (BOOL)isPlaybackPaused
{
    PINAssertMain();
    return _playbackPaused;
}

- (void)setPlaybackPaused:(BOOL)playbackPaused
{
    PINAssertMain();
    
    _playbackPaused = playbackPaused;
    [self checkIfShouldAnimate];
}

- (void)coverImageCompleted:(UIImage *)coverImage
{
    PINAssertMain();
    BOOL setCoverImage = (_displayLink == nil) || _displayLink.paused;
    
    if (setCoverImage) {
        [self setCoverImage:coverImage];
    }
}

- (void)setCoverImage:(UIImage *)coverImage
{
    PINAssertMain();
    if (_frameImage) {
        CGImageRelease(_frameImage);
    }
    _frameImage = CGImageRetain([coverImage CGImage]);
}

#pragma mark - Animating

- (void)checkIfShouldAnimate
{
    PINAssertMain();
    BOOL shouldAnimate = _playbackPaused == NO && _animatedImage.playbackReady && [self canBeVisible];
    if (shouldAnimate) {
        [self startAnimating];
    } else {
        [self stopAnimating];
    }
}

- (void)startAnimating
{
    PINAssertMain();
    if (_playbackPaused) {
        return;
    }
    
    if (_animatedImage.playbackReady == NO) {
        return;
    }
    
    if ([self canBeVisible] == NO) {
        return;
    }
    
    // Get frame interval before holding display link lock to avoid deadlock
    NSUInteger frameInterval = self.animatedImage.frameInterval;

    if (_displayLink == nil) {
        _playHead = 0;
        _displayLink = [CADisplayLink displayLinkWithTarget:[PINWeakProxy weakProxyWithTarget:self] selector:@selector(displayLinkFired:)];
        _displayLink.frameInterval = frameInterval;
        _lastSuccessfulFrameIndex = NSUIntegerMax;
        
        [_displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:self.animatedImageRunLoopMode];
    } else {
        _displayLink.paused = NO;
    }
}

- (void)stopAnimating
{
    PINAssertMain();

    _displayLink.paused = YES;
    _lastDisplayLinkFire = 0;
    
    [_animatedImage clearAnimatedImageCache];
}

#pragma mark - Overrides

- (UIImage *)image
{
    PINAssertMain();
    if (_animatedImage) {
        return [UIImage imageWithCGImage:_frameImage];
    }
    return [super image];
}

- (CGImageRef)imageRef
{
    PINAssertMain();
    if (_animatedImage) {
        return _frameImage;
    } else if ([super image]) {
        return (CGImageRef)CFAutorelease([[super image] CGImage]);
    }
    return nil;
}

- (void)setImage:(UIImage *)image
{
    PINAssertMain();
    if (image) {
        self.animatedImage = nil;
    }
    
    super.image = image;
}

- (void)displayLayer:(CALayer *)layer
{
    PINAssertMain();
    layer.contents = (__bridge id)[self imageRef];
}

- (void)didMoveToWindow
{
    [super didMoveToWindow];
    [self updateAnimationForPossibleVisibility];
}

- (void)didMoveToSuperview
{
    [super didMoveToSuperview];
    [self updateAnimationForPossibleVisibility];
}

- (void)setAlpha:(CGFloat)alpha
{
    [super setAlpha:alpha];
    [self updateAnimationForPossibleVisibility];
}

- (void)setHidden:(BOOL)hidden
{
    [super setHidden:hidden];
    [self updateAnimationForPossibleVisibility];
}

#pragma mark - Display Link Callbacks

- (BOOL)canBeVisible
{
    return self.window && self.superview && self.isHidden == NO && self.alpha > 0.0;
}

- (void)updateAnimationForPossibleVisibility
{
    [self checkIfShouldAnimate];
}

+ (BOOL)displayLinkSupportsTargetTimestamp
{
    static dispatch_once_t onceToken;
    static BOOL supportsTargetTimestamp;
    dispatch_once(&onceToken, ^{
        supportsTargetTimestamp = [[CADisplayLink class] instancesRespondToSelector:@selector(targetTimestamp)];
    });
    return supportsTargetTimestamp;
}

- (void)displayLinkFired:(CADisplayLink *)displayLink
{
    PINAssertMain();
    CFTimeInterval timeBetweenLastFire;
    if (_lastDisplayLinkFire == 0) {
        timeBetweenLastFire = 0;
    } else {
#if __IPHONE_OS_VERSION_MIN_REQUIRED >= __IPHONE_10_0
        if ([[self class] displayLinkSupportsTargetTimestamp]){
            timeBetweenLastFire = displayLink.targetTimestamp - displayLink.timestamp;
        } else {
            timeBetweenLastFire = CACurrentMediaTime() - self.lastDisplayLinkFire;
        }
#else
        timeBetweenLastFire = CACurrentMediaTime() - self.lastDisplayLinkFire;
#endif
    }
    
    self.lastDisplayLinkFire = CACurrentMediaTime();
    
    _playHead += timeBetweenLastFire;
    
    while (_playHead > self.animatedImage.totalDuration) {
        // Set playhead to zero to keep from showing different frames on different playthroughs
        _playHead = 0;
        _playedLoops++;
    }
    
    if (self.animatedImage.loopCount > 0 && _playedLoops >= self.animatedImage.loopCount) {
        [self stopAnimating];
        return;
    }
    
    NSUInteger frameIndex = [self frameIndexAtPlayHeadPosition:_playHead];
    if (frameIndex == _lastSuccessfulFrameIndex) {
        return;
    }
    CGImageRef frameImage = [self.animatedImage imageAtIndex:frameIndex];
    
    if (frameImage == nil) {
        //Pause the display link until we get a file ready notification
        displayLink.paused = YES;
        self.lastDisplayLinkFire = 0;
    } else {
        [self.layer setNeedsDisplay];
        if (_frameImage) {
            CGImageRelease(_frameImage);
        }
        _frameImage = CGImageRetain(frameImage);
        _lastSuccessfulFrameIndex = frameIndex;
    }
}

- (NSUInteger)frameIndexAtPlayHeadPosition:(CFTimeInterval)playHead
{
    PINAssertMain();
    NSUInteger frameIndex = 0;
    for (NSUInteger durationIndex = 0; durationIndex < self.animatedImage.frameCount; durationIndex++) {
        playHead -= [self.animatedImage durationAtIndex:durationIndex];
        if (playHead < 0) {
            return frameIndex;
        }
        frameIndex++;
    }
    
    return frameIndex;
}

@end

@interface PINWeakProxy ()
{
    __weak id _target;
    Class _targetClass;
}
@end

@implementation PINWeakProxy

+ (PINWeakProxy *)weakProxyWithTarget:(id)target
{
    return [[PINWeakProxy alloc] initWithTarget:target];
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
