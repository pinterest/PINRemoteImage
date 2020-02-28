//
//  APNGViewController.m
//  PINRemoteImage
//
//  Created by SAGESSE on 2020/2/28.
//  Copyright © 2020 Garrett Moon. All rights reserved.
//

#import "APNGViewController.h"

#import <PINRemoteImage/PINImageView+PINRemoteImage.h>

@interface APNGViewController ()

@end

@implementation APNGViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.animatedImageView pin_setImageFromURL:[NSURL URLWithString:@"http://littlesvr.ca/apng/images/o_sample.png"]];
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
