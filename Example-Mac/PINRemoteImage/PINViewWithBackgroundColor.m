//
//  PINViewWithBackgroundColor.m
//  PINRemoteImage
//
//  Created by Michael Schneider on 1/5/16.
//  Copyright © 2016 mischneider. All rights reserved.
//

#import "PINViewWithBackgroundColor.h"

@implementation PINViewWithBackgroundColor


#pragma mark - Lifecycle

- (instancetype)init
{
    self = [super init];
    if (self == nil) { return self; }
    [self initPINViewWithBackgroundColor];
    return self;
}


- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self == nil) { return self; }
    [self initPINViewWithBackgroundColor];
    return self;
}

- (void)initPINViewWithBackgroundColor
{
    self.wantsLayer = YES;
}


#pragma mark - NSView

- (BOOL)wantsUpdateLayer
{
    return YES;
}

- (void)updateLayer
{
    self.layer.backgroundColor = self.backgroundColor.CGColor;
}


#pragma mark - Setter

- (void)setBackgroundColor:(NSColor *)backgroundColor
{
    _backgroundColor = backgroundColor;
    [self setNeedsDisplay:YES];
}

@end
