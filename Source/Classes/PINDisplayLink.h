//
//  PINDisplayLink.h
//  Pods
//
//  Created by Garrett Moon on 4/23/18.
//

#import <Foundation/Foundation.h>

#import "PINRemoteImageMacros.h"

#if PIN_TARGET_IOS
#define PINDisplayLink CADisplayLink
#elif PIN_TARGET_MAC
@interface PINDisplayLink : NSObject

+ (PINDisplayLink *)displayLinkWithTarget:(id)target selector:(SEL)sel;
- (void)addToRunLoop:(NSRunLoop *)runloop forMode:(NSRunLoopMode)mode;
- (void)removeFromRunLoop:(NSRunLoop *)runloop forMode:(NSRunLoopMode)mode;

@property(getter=isPaused, nonatomic) BOOL paused;
@property(nonatomic) NSInteger frameInterval;

@end
#endif
