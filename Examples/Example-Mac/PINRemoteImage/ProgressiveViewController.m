//
//  ProgressiveViewController.m
//  PINRemoteImage
//
//  Created by Michael Schneider on 1/6/16.
//  Copyright © 2016 mischneider. All rights reserved.
//

#import "ProgressiveViewController.h"

#import <PINRemoteImage/PINImageView+PINRemoteImage.h>
#import <PINRemoteImage/PINRemoteImageCaching.h>

@interface ProgressiveViewController ()
@property (weak) IBOutlet NSImageView *imageView;

@end

@implementation ProgressiveViewController

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
    
    // MUST BE SET ON IMAGE VIEW TO GET PROGRESS UPDATES!
    self.imageView.pin_updateWithProgress = YES;
}

- (void)viewDidAppear
{
    [super viewDidAppear];
    
    NSURL *progressiveURL = [NSURL URLWithString:@"https://s-media-cache-ak0.pinimg.com/1200x/2e/0c/c5/2e0cc5d86e7b7cd42af225c29f21c37f.jpg"];
    [[PINRemoteImageManager sharedImageManager] setProgressThresholds:@[@(0.1), @(0.2), @(0.3), @(0.4), @(0.5), @(0.6), @(0.7), @(0.8), @(0.9)] completion:nil];
    [[[PINRemoteImageManager sharedImageManager] cache] removeObjectForKey:[[PINRemoteImageManager sharedImageManager] cacheKeyForURL:progressiveURL processorKey:nil]];
    [self.imageView pin_setImageFromURL:progressiveURL];
    
    NSMutableArray *progress = [[NSMutableArray alloc] init];
    [[PINRemoteImageManager sharedImageManager]
     downloadImageWithURL:progressiveURL
     options:PINRemoteImageManagerDownloadOptionsNone progressImage:^(PINRemoteImageManagerResult *result) {
         [progress addObject:result.image];
     } completion:^(PINRemoteImageManagerResult *result) {
         [progress addObject:result.image];
     }];
}

@end
