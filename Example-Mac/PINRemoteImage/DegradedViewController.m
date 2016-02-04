//
//  DegradedViewController.m
//  PINRemoteImage
//
//  Created by Michael Schneider on 1/6/16.
//  Copyright © 2016 mischneider. All rights reserved.
//

#import "DegradedViewController.h"

#import <PINRemoteImage/PINImageView+PINRemoteImage.h>

@interface DegradedViewController ()
@property (weak) IBOutlet NSImageView *imageView;
@end

@implementation DegradedViewController

#pragma mark - Lifecycle

- (instancetype)init
{
    self = [super initWithNibName:NSStringFromClass(self.class) bundle:nil];
    if (self == nil) { return self; }
    return self;
}


#pragma mark - NSViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[PINRemoteImageManager sharedImageManager] setShouldUpgradeLowQualityImages:YES completion:nil];
}


- (void)viewWillAppear
{
    [super viewWillAppear];
    
    [self.imageView pin_setImageFromURLs:@[[NSURL URLWithString:@"https://placekitten.com/101/101"],
                                           [NSURL URLWithString:@"https://placekitten.com/401/401"],
                                           [NSURL URLWithString:@"https://placekitten.com/801/801"]]];
}

@end
