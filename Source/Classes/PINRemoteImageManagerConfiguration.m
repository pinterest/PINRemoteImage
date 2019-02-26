//
//  PINRemoteImageManagerConfiguration.m
//  Pods
//
//  Created by Ryan Quan on 2/22/19.
//
//

#import "PINRemoteImageManagerConfiguration.h"

#import "PINRemoteImageManager.h"

@implementation PINRemoteImageManagerConfiguration

- (nonnull instancetype)init {
    if (self = [super init]) {
        _maxConcurrentOperations = [[NSProcessInfo processInfo] activeProcessorCount] * 2;
        _maxConcurrentDownloads = 10;
        _estimatedRemainingTimeThreshold = 0.1;
        _shouldBlurProgressive = YES;
        _maxProgressiveRenderSize = CGSizeMake(1024, 1024);
        _highQualityBPSThreshold = 500000;
        _lowQualityBPSThreshold = 50000; // approximately edge speed
        _shouldUpgradeLowQualityImages = NO;
    }
    return self;
}

#pragma mark - Setters

- (void)setMaxConcurrentDownloads:(NSUInteger)maxConcurrentDownloads {
    NSAssert(maxConcurrentDownloads <= PINRemoteImageHTTPMaximumConnectionsPerHost, @"maxNumberOfConcurrentDownloads must be less than or equal to %d", PINRemoteImageHTTPMaximumConnectionsPerHost);
    _maxConcurrentDownloads = maxConcurrentDownloads;
}

@end
