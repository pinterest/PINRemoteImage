//
//  AnimatedWebPViewController.m
//  Example-Mac
//
//  Created by Andy Finnell on 5/15/24.
//  Copyright © 2024 mischneider. All rights reserved.
//

#import "AnimatedWebPViewController.h"
#import <PINRemoteImage/PINRemoteImage.h>

@interface AnimatedWebPViewController ()
@property (weak) IBOutlet PINAnimatedImageView *animatedImageView;
@end

@implementation AnimatedWebPViewController

- (void)viewWillAppear {
    [super viewWillAppear];
    [self.animatedImageView pin_setImageFromURL:[NSURL URLWithString:@"https://mathiasbynens.be/demo/animated-webp-supported.webp"]];
}

@end
