//
//  GIFViewController.m
//  PINRemoteImage
//
//  Created by Garrett Moon on 4/17/18.
//  Copyright © 2018 Garrett Moon. All rights reserved.
//

#import "GIFViewController.h"

#import <PINRemoteImage/PINImageView+PINRemoteImage.h>

@interface GIFViewController ()

@end

@implementation GIFViewController

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
    [self.animatedImageView pin_setImageFromURL:[NSURL URLWithString:@"https://i.pinimg.com/originals/f5/23/f1/f523f141646b613f78566ba964208990.gif"]];
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
