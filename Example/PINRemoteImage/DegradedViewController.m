//
//  DegradedViewController.m
//  PINRemoteImage
//
//  Created by Garrett Moon on 7/14/15.
//  Copyright (c) 2015 Garrett Moon. All rights reserved.
//

#import "DegradedViewController.h"

#import <PINRemoteImage/PINImageView+PINRemoteImage.h>

@interface DegradedViewController ()

@end

@implementation DegradedViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [[PINRemoteImageManager sharedImageManager] setShouldUpgradeLowQualityImages:YES completion:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.imageView pin_setImageFromURLs:@[[NSURL URLWithString:@"https://placekitten.com/101/101"],
                                           [NSURL URLWithString:@"https://placekitten.com/401/401"],
                                           [NSURL URLWithString:@"https://placekitten.com/801/801"]]];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
