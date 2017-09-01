//
//  PINSpeedRecorder.h
//  PINRemoteImage
//
//  Created by Garrett Moon on 8/30/17.
//  Copyright © 2017 Pinterest. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum : NSUInteger {
    PINSpeedRecorderConnectionStatusNotReachable,
    PINSpeedRecorderConnectionStatusWWAN,
    PINSpeedRecorderConnectionStatusWiFi
} PINSpeedRecorderConnectionStatus;

@interface PINSpeedRecorder : NSObject

+ (PINSpeedRecorder *)sharedRecorder;
+ (NSUInteger)appropriateImageIdxForURLsGivenHistoricalNetworkConditions:(NSArray <NSURL *> *)urls
                                                  lowQualityQPSThreshold:(float)lowQualityQPSThreshold
                                                 highQualityQPSThreshold:(float)highQualityQPSThreshold;

- (void)addTaskBPS:(float)bytesPerSecond endDate:(NSDate *)endDate;
- (float)currentBytesPerSecond;
- (PINSpeedRecorderConnectionStatus)connectionStatus;

#if DEBUG
- (void)setCurrentBytesPerSecond:(float)currentBPS;
#endif

@end
