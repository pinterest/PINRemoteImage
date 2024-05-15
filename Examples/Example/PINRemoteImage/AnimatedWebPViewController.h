//
//  AnimatedWebPViewController.h
//  Example
//
//  Created by Andy Finnell on 5/15/24.
//  Copyright © 2024 Garrett Moon. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <PINRemoteImage/PINAnimatedImageView.h>

NS_ASSUME_NONNULL_BEGIN

@interface AnimatedWebPViewController : UIViewController

@property (nonatomic, weak) IBOutlet PINAnimatedImageView *animatedImageView;

@end

NS_ASSUME_NONNULL_END
