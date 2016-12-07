//
//  ProcessingViewController.m
//  PINRemoteImage
//
//  Created by Michael Schneider on 1/6/16.
//  Copyright © 2016 mischneider. All rights reserved.
//

#import "ProcessingViewController.h"

#import <PINRemoteImage/PINImageView+PINRemoteImage.h>
#import <PINRemoteImage/PINImage+DecodedImage.h>

@interface ProcessingViewController ()
@property (weak) IBOutlet NSImageView *imageView;

@end

@implementation ProcessingViewController

#pragma mark - Lifecycle

- (instancetype)init
{
    self = [super initWithNibName:NSStringFromClass(self.class) bundle:nil];
    if (self == nil) { return self; }
    return self;
}


#pragma mark - NSViewController

- (void)viewWillAppear
{
    [super viewWillAppear];
    
    [self.imageView pin_setImageFromURL:[NSURL URLWithString:@"https://s-media-cache-ak0.pinimg.com/736x/5b/c6/c5/5bc6c5387ff6f104fd642f2b375efba3.jpg"] processorKey:@"rounded" processor:^NSImage *(PINRemoteImageManagerResult *result, NSUInteger *cost)
     {
         NSImage *image = result.image;
         CGFloat radius = 7.0f;
         CGSize targetSize = CGSizeMake(200, 300);
         CGRect imageRect = CGRectMake(0, 0, targetSize.width, targetSize.height);

         NSImage *processedImage = [[NSImage alloc] initWithSize:targetSize];
         [processedImage lockFocus];
         
         NSBezierPath *bezierPath = [NSBezierPath bezierPathWithRoundedRect:imageRect xRadius:radius yRadius:radius];
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
         
         [[NSColor redColor] setStroke];
         [bezierPath setLineWidth:5.0];
         [bezierPath stroke];
        
         NSImage *logo = [NSImage imageNamed:@"white-pinterest-logo"];
         CGContextRef ctx = [[NSGraphicsContext currentContext] graphicsPort];
         CGContextSetBlendMode(ctx, kCGBlendModeOverlay);
         CGContextSetAlpha(ctx, 0.5);
         CGContextDrawImage(ctx, CGRectMake(90, 10, logo.size.width, logo.size.height), [logo CGImage]);
         
         [processedImage unlockFocus];
         
         return processedImage;
     }];
}

@end
