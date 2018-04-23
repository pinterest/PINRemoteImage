//
//  PINAnimatedImageView.h
//  Pods
//
//  Created by Garrett Moon on 4/17/18.
//

#import <UIKit/UIKit.h>

#import <PINRemoteImage/PINCachedAnimatedImage.h>

@interface PINAnimatedImageView : UIImageView

- (instancetype)initWithAnimatedImage:(PINCachedAnimatedImage *)animatedImage NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithFrame:(CGRect)frame NS_DESIGNATED_INITIALIZER;
- (nullable instancetype)initWithCoder:(NSCoder *)aDecoder NS_DESIGNATED_INITIALIZER;

@property (nonatomic, strong) PINCachedAnimatedImage *animatedImage;
@property (nonatomic, strong) NSString *animatedImageRunLoopMode;
@property (nonatomic, assign, getter=isPlaybackPaused) BOOL playbackPaused;

@end
