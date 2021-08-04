//
//  GIFViewController.m
//  PINRemoteImage
//
//  Created by Garrett Moon on 4/23/18.
//  Copyright © 2018 mischneider. All rights reserved.
//

#import "GIFViewController.h"

#import "PINAnimatedImageView+PINRemoteImage.h"

@interface GIFViewController ()

@property (weak) IBOutlet PINAnimatedImageView *animatedImageView;

@end

@implementation GIFViewController

- (void)viewWillAppear {
    [super viewWillAppear];
    [self.animatedImageView pin_setImageFromURL:[NSURL URLWithString:@"https://i.pinimg.com/originals/f5/23/f1/f523f141646b613f78566ba964208990.gif"]];
}

@end
