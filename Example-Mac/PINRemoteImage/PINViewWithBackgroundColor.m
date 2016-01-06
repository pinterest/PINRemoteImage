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
    
}


#pragma mark - Drawing

- (void)drawRect:(NSRect)dirtyRect
{
    [super drawRect:dirtyRect];
    
    if (self.backgroundColor != nil) {
        [self.backgroundColor setFill];
        NSRectFill(dirtyRect);
    }
}

@end
