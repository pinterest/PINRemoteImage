//
//  ProcessingViewController.m
//  PINRemoteImage
//
//  Created by Garrett Moon on 7/16/15.
//  Copyright (c) 2015 Garrett Moon. All rights reserved.
//

#import "ProcessingViewController.h"

#import <PINRemoteImage/PINImageView+PINRemoteImage.h>

@interface ProcessingViewController ()

@end

@implementation ProcessingViewController

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

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self.imageView pin_setImageFromURL:[NSURL URLWithString:@"https://s-media-cache-ak0.pinimg.com/736x/5b/c6/c5/5bc6c5387ff6f104fd642f2b375efba3.jpg"] processorKey:@"rounded" processor:^UIImage *(PINRemoteImageManagerResult *result, NSUInteger *cost)
     {
         UIImage *image = result.image;
         CGFloat radius = 7.0f;
         CGSize targetSize = CGSizeMake(200, 300);
         CGRect imageRect = CGRectMake(0, 0, targetSize.width, targetSize.height);
         UIGraphicsBeginImageContext(imageRect.size);
         UIBezierPath *bezierPath = [UIBezierPath bezierPathWithRoundedRect:imageRect cornerRadius:radius];
         [bezierPath addClip];
         
         CGFloat widthMultiplier = targetSize.width / image.size.width;
         CGFloat heightMultiplier = targetSize.height / image.size.height;
         CGFloat sizeMultiplier = MAX(widthMultiplier, heightMultiplier);
         
         CGRect drawRect = CGRectMake(0, 0, image.size.width * sizeMultiplier, image.size.height * sizeMultiplier);
         if (CGRectGetMaxX(drawRect) > CGRectGetMaxX(imageRect)) {
             drawRect.origin.x -= (CGRectGetMaxX(drawRect) - CGRectGetMaxX(imageRect)) / 2.0;
         }
         if (CGRectGetMaxY(drawRect) > CGRectGetMaxY(imageRect)) {
             drawRect.origin.y -= (CGRectGetMaxY(drawRect) - CGRectGetMaxY(imageRect)) / 2.0;
         }
         
         [image drawInRect:drawRect];
         
         [[UIColor redColor] setStroke];
         [bezierPath setLineWidth:5.0];
         [bezierPath stroke];
        
         CGContextRef ctx = UIGraphicsGetCurrentContext();
         CGContextSetBlendMode(ctx, kCGBlendModeOverlay);
         CGContextSetAlpha(ctx, 0.5);
         
         UIImage *logo = [UIImage imageNamed:@"white-pinterest-logo"];
         CGContextScaleCTM(ctx, 1.0, -1.0);
         CGContextTranslateCTM(ctx, 0.0, -drawRect.size.height);
         CGContextDrawImage(ctx, CGRectMake(90, 10, logo.size.width, logo.size.height), [logo CGImage]);
         
         UIImage *processedImage = UIGraphicsGetImageFromCurrentImageContext();
         UIGraphicsEndImageContext();
         return processedImage;
     }];
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
