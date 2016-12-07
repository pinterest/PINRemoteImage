//
//  AppDelegate.m
//  PINRemoteImage
//
//  Created by Michael Schneider on 1/3/16.
//  Copyright © 2016 mischneider. All rights reserved.
//

#import "AppDelegate.h"

#import <PINRemoteImage/PINRemoteImageManager.h>

#import "ScrollViewController.h"
#import "WebPViewController.h"
#import "DegradedViewController.h"
#import "ProgressiveViewController.h"
#import "ProcessingViewController.h"

enum : NSUInteger {
    kScrollViewControllerSegment = 0,
    kWebPViewControllerSegment,
    kProgressiveViewControllerSegment,
    kDegradedViewControllerSegment,
    kProcessingViewControllerSegment,
};

@interface AppDelegate ()
@property (weak) IBOutlet NSWindow *window;
@property (weak) IBOutlet NSSegmentedControl *segmentedControl;

@property (nonatomic, strong) NSViewController *currentViewController;
@property (nonatomic, copy, readonly) NSDictionary *viewControllerMapping;
@property (nonatomic, strong) NSMutableDictionary *viewControllerCache;

@end

@implementation AppDelegate


#pragma mark - NSNibAwakening

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    self.window.titleVisibility = NSWindowTitleHidden;
    self.segmentedControl.selectedSegment = 0;
    self.viewControllerCache = [NSMutableDictionary dictionary];
}


#pragma mark - NSApplicationDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [[PINRemoteImageManager sharedImageManager] setProgressiveRendersMaxProgressiveRenderSize:CGSizeMake(2048, 2048) completion:nil];
    [self segmentedControlChanged:self.segmentedControl];
}


#pragma mark - Mapping

- (NSDictionary *)viewControllerMapping
{
    static NSDictionary *mapping = nil;
    if (mapping == nil) {
        mapping = @{
            @(kScrollViewControllerSegment) : [ScrollViewController class],
            @(kWebPViewControllerSegment) : [WebPViewController class],
            @(kProgressiveViewControllerSegment) : [ProgressiveViewController class],
            @(kDegradedViewControllerSegment) : [DegradedViewController class],
            @(kProcessingViewControllerSegment) : [ProcessingViewController class]
        };
    }

    return [mapping copy];
}


#pragma mark - Actions

- (IBAction)segmentedControlChanged:(NSSegmentedControl *)segmentedControl
{
    [self.currentViewController.view removeFromSuperview];
    
    NSInteger selectedSegment = segmentedControl.selectedSegment;
    NSViewController *viewController = self.viewControllerCache[@(selectedSegment)];
    if (viewController == nil) {
        viewController = [self.viewControllerMapping[@(selectedSegment)] new];
        viewController.view.autoresizingMask = NSViewHeightSizable | NSViewWidthSizable;
        
        self.viewControllerCache[@(selectedSegment)] = viewController;
    }
    self.currentViewController = viewController;
    
    self.currentViewController.view.frame = self.window.contentView.bounds;
    [self.window.contentView addSubview:self.currentViewController.view];
}

@end