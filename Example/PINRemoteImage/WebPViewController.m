//
//  WebPViewController.m
//  PINRemoteImage
//
//  Created by Garrett Moon on 7/14/15.
//  Copyright (c) 2015 Garrett Moon. All rights reserved.
//

#import "WebPViewController.h"

#import <PINRemoteImage/PINImageView+PINRemoteImage.h>

@interface WebPViewController ()

@end

@implementation WebPViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.imageView pin_setImageFromURL:[NSURL URLWithString:@"https://github.com/samdutton/simpl/blob/master/picturetype/kittens.webp?raw=true"]];
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
