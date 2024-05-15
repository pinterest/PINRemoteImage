//
//  AnimatedWebPViewController.m
//  Example
//
//  Created by Andy Finnell on 5/15/24.
//  Copyright © 2024 Garrett Moon. All rights reserved.
//

#import "AnimatedWebPViewController.h"
#import <PINRemoteImage/PINImageView+PINRemoteImage.h>

@interface AnimatedWebPViewController ()

@end

@implementation AnimatedWebPViewController

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.animatedImageView pin_setImageFromURL:[NSURL URLWithString:@"https://mathiasbynens.be/demo/animated-webp-supported.webp"]];
}

@end
