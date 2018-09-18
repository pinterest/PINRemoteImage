//
//  PINAnimatedImageView.h
//  Pods
//
//  Created by Garrett Moon on 4/17/18.
//

#if PIN_TARGET_IOS
#import <UIKit/UIKit.h>
#elif PIN_TARGET_MAC
#import <Cocoa/Cocoa.h>
#endif

#import <PINRemoteImage/PINCachedAnimatedImage.h>

@interface PINAnimatedImageView : PINImageView

- (nonnull instancetype)initWithAnimatedImage:(nonnull PINCachedAnimatedImage *)animatedImage NS_DESIGNATED_INITIALIZER;
- (nonnull instancetype)initWithFrame:(CGRect)frame NS_DESIGNATED_INITIALIZER;
- (nullable instancetype)initWithCoder:(nonnull NSCoder *)aDecoder NS_DESIGNATED_INITIALIZER;

@property (nullable, nonatomic, strong) PINCachedAnimatedImage *animatedImage;
@property (nullable, nonatomic, strong) NSString *animatedImageRunLoopMode;
@property (nonatomic, assign, getter=isPlaybackPaused) BOOL playbackPaused;

/**
 @abstract Seek to a play head position of an animated image.
 */
- (void)seekToImageAtPlayHeadPosition:(CFTimeInterval)playHead;

@end
