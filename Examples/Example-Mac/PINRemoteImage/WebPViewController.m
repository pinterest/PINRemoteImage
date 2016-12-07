//
//  WebPViewController.m
//  PINRemoteImage
//
//  Created by Michael Schneider on 1/6/16.
//  Copyright © 2016 mischneider. All rights reserved.
//

#import "WebPViewController.h"

#import <PINRemoteImage/PINImageView+PINRemoteImage.h>

@interface WebPViewController ()
@property (weak) IBOutlet NSImageView *imageView;
@end

@implementation WebPViewController

#pragma mark - Lifecycle

- (instancetype)init
{
    self = [super initWithNibName:NSStringFromClass(self.class) bundle:nil];
    if (self == nil) { return self; }
    return self;
}


#pragma mark - NSViewController

- (void)viewDidAppear
{
    [super viewDidAppear];
    
    [self.imageView pin_setImageFromURL:[NSURL URLWithString:@"https://github.com/samdutton/simpl/blob/master/picturetype/kittens.webp?raw=true"]];
}

@end
