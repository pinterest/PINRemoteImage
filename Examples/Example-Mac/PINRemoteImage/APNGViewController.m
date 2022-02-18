//
//  APNGViewController.m
//  PINRemoteImage
//
//  Created by Garrett Moon on 4/23/18.
//  Copyright © 2018 mischneider. All rights reserved.
//

#import "APNGViewController.h"

#import "PINAnimatedImageView+PINRemoteImage.h"

@interface APNGViewController ()

@property (weak) IBOutlet PINAnimatedImageView *animatedImageView;

@end

@implementation APNGViewController

- (void)viewWillAppear {
    [super viewWillAppear];
    [self.animatedImageView pin_setImageFromURL:[NSURL URLWithString:@"https://upload.wikimedia.org/wikipedia/commons/1/14/Animated_PNG_example_bouncing_beach_ball.png"]];
}

@end
