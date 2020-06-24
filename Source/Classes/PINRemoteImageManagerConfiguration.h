//
//  PINRemoteImageManagerConfiguration.h
//  Pods
//
//  Created by Ryan Quan on 2/22/19.
//
//

#import <Foundation/Foundation.h>

#import "PINRemoteImageMacros.h"

#if PIN_TARGET_IOS
#import <UIKit/UIKit.h>
#elif PIN_TARGET_MAC
#import <Cocoa/Cocoa.h>
#endif

/** A configuration object used to customize a PINRemoteImageManager instance **/
@interface PINRemoteImageManagerConfiguration : NSObject

/** The maximum number of concurrent operations. Defaults to NSOperationQueueDefaultMaxConcurrentOperationCount. */
@property (nonatomic, readwrite, assign) NSUInteger maxConcurrentOperations;

/** The maximum number of concurrent downloads. Defaults to 10, maximum 65535. */
@property (nonatomic, readwrite, assign) NSUInteger maxConcurrentDownloads;

/** The estimated remaining time threshold used to decide to skip progressive rendering. Defaults to 0.1. */
@property (nonatomic, readwrite, assign) NSTimeInterval estimatedRemainingTimeThreshold;

/** A bool value indicating whether PINRemoteImage should blur progressive render results */
@property (nonatomic, readwrite, assign) BOOL shouldBlurProgressive;

/** A CGSize which indicates the max size PINRemoteImage will render a progressive image. If an image is larger in either dimension, progressive rendering will be skipped */
@property (nonatomic, readwrite, assign) CGSize maxProgressiveRenderSize;

/** The minimum BPS to download the highest quality image in a set. */
@property (nonatomic, readwrite, assign) float highQualityBPSThreshold;

/** The maximum BPS to download the lowest quality image in a set. */
@property (nonatomic, readwrite, assign) float lowQualityBPSThreshold;

/** Whether high quality images should be downloaded when a low quality image is cached if network connectivity has improved. */
@property (nonatomic, readwrite, assign) BOOL shouldUpgradeLowQualityImages;

@end
