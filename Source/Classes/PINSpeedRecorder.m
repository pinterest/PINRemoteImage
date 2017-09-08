//
//  PINSpeedRecorder.m
//  PINRemoteImage
//
//  Created by Garrett Moon on 8/30/17.
//  Copyright © 2017 Pinterest. All rights reserved.
//

#import "PINSpeedRecorder.h"

#import <SystemConfiguration/SystemConfiguration.h>
#import <netinet/in.h>

#import "PINRemoteLock.h"

static const NSUInteger kMaxRecordedTasks = 5;

@interface PINTaskQOS : NSObject

- (instancetype)initWithBPS:(float)bytesPerSecond endDate:(NSDate *)endDate;

@property (nonatomic, strong) NSDate *endDate;
@property (nonatomic, assign) float bytesPerSecond;

@end

@interface PINSpeedRecorder ()
{
    NSMutableArray <PINTaskQOS *> *_taskQOS;
    SCNetworkReachabilityRef _reachability;
#if DEBUG
    BOOL _overrideBPS;
    float _currentBPS;
#endif
}

@property (nonatomic, strong) PINRemoteLock *lock;

@end

@implementation PINSpeedRecorder

+ (PINSpeedRecorder *)sharedRecorder
{
    static dispatch_once_t onceToken;
    static PINSpeedRecorder *sharedRecorder;
    dispatch_once(&onceToken, ^{
        sharedRecorder = [[self alloc] init];
    });
    
    return sharedRecorder;
}

- (instancetype)init
{
    if (self = [super init]) {
        _lock = [[PINRemoteLock alloc] initWithName:@"PINSpeedRecorder lock"];
        _taskQOS = [[NSMutableArray alloc] initWithCapacity:kMaxRecordedTasks];
        
        struct sockaddr_in zeroAddress;
        bzero(&zeroAddress, sizeof(zeroAddress));
        zeroAddress.sin_len = sizeof(zeroAddress);
        zeroAddress.sin_family = AF_INET;
        _reachability = SCNetworkReachabilityCreateWithAddress(kCFAllocatorDefault, (const struct sockaddr *)&zeroAddress);
    }
    return self;
}

- (void)addTaskBPS:(float)bytesPerSecond endDate:(NSDate *)endDate
{
    //if bytesPerSecond is less than or equal to zero, ignore.
    if (bytesPerSecond <= 0) {
        return;
    }
    
    [self.lock lockWithBlock:^{
        if (_taskQOS.count >= kMaxRecordedTasks) {
            [_taskQOS removeObjectAtIndex:0];
        }
        
        PINTaskQOS *taskQOS = [[PINTaskQOS alloc] initWithBPS:bytesPerSecond endDate:endDate];
        
        [_taskQOS addObject:taskQOS];
        [_taskQOS sortUsingComparator:^NSComparisonResult(PINTaskQOS *obj1, PINTaskQOS *obj2) {
            return [obj1.endDate compare:obj2.endDate];
        }];
    }];
}

- (float)currentBytesPerSecond
{
    __block NSUInteger count = 0;
    __block float bps = 0;
    __block BOOL valid = NO;
    [self.lock lockWithBlock:^{
#if DEBUG
        if (_overrideBPS) {
            bps = _currentBPS;
            count = 1;
            valid = YES;
            return;
        }
#endif
        
        const NSTimeInterval validThreshold = 60.0;
        
        NSDate *threshold = [NSDate dateWithTimeIntervalSinceNow:-validThreshold];
        [_taskQOS enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(PINTaskQOS *taskQOS, NSUInteger idx, BOOL *stop) {
            if ([taskQOS.endDate compare:threshold] == NSOrderedAscending) {
                *stop = YES;
                return;
            }
            valid = YES;
            count++;
            bps += taskQOS.bytesPerSecond;
            
        }];
    }];
    
    if (valid == NO) {
        return -1;
    }
    
    return bps / (float)count;
}

#if DEBUG
- (void)setCurrentBytesPerSecond:(float)currentBPS
{
    [self.lock lockWithBlock:^{
        _overrideBPS = YES;
        _currentBPS = currentBPS;
    }];
}
#endif

// Cribbed from Apple's reachability: https://developer.apple.com/library/content/samplecode/Reachability/Listings/Reachability_Reachability_m.html#//apple_ref/doc/uid/DTS40007324-Reachability_Reachability_m-DontLinkElementID_9

- (PINSpeedRecorderConnectionStatus)connectionStatus
{
    PINSpeedRecorderConnectionStatus status = PINSpeedRecorderConnectionStatusNotReachable;
    SCNetworkReachabilityFlags flags;
    
    // _reachability is set on init and therefore safe to access outside the lock
    if (SCNetworkReachabilityGetFlags(_reachability, &flags)) {
        return [self networkStatusForFlags:flags];
    }
    return status;
}

- (PINSpeedRecorderConnectionStatus)networkStatusForFlags:(SCNetworkReachabilityFlags)flags
{
    if ((flags & kSCNetworkReachabilityFlagsReachable) == 0) {
        // The target host is not reachable.
        return PINSpeedRecorderConnectionStatusNotReachable;
    }
    
    PINSpeedRecorderConnectionStatus connectionStatus = PINSpeedRecorderConnectionStatusNotReachable;
    
    if ((flags & kSCNetworkReachabilityFlagsConnectionRequired) == 0) {
        /*
         If the target host is reachable and no connection is required then we'll assume (for now) that you're on Wi-Fi...
         */
        connectionStatus = PINSpeedRecorderConnectionStatusWiFi;
    }
    
    if ((((flags & kSCNetworkReachabilityFlagsConnectionOnDemand ) != 0) || (flags & kSCNetworkReachabilityFlagsConnectionOnTraffic) != 0)) {
        /*
         ... and the connection is on-demand (or on-traffic) if the calling application is using the CFSocketStream or higher APIs...
         */
        
        if ((flags & kSCNetworkReachabilityFlagsInterventionRequired) == 0) {
            /*
             ... and no [user] intervention is needed...
             */
            connectionStatus = PINSpeedRecorderConnectionStatusWiFi;
        }
    }
    
#if PIN_TARGET_IOS
    if ((flags & kSCNetworkReachabilityFlagsIsWWAN) == kSCNetworkReachabilityFlagsIsWWAN) {
        /*
         ... but WWAN connections are OK if the calling application is using the CFNetwork APIs.
         */
        connectionStatus = PINSpeedRecorderConnectionStatusWWAN;
    }
#endif
    
    return connectionStatus;
}

+ (NSUInteger)appropriateImageIdxForURLsGivenHistoricalNetworkConditions:(NSArray <NSURL *> *)urls
                                                  lowQualityQPSThreshold:(float)lowQualityQPSThreshold
                                                 highQualityQPSThreshold:(float)highQualityQPSThreshold
{
    float currentBytesPerSecond = [[PINSpeedRecorder sharedRecorder] currentBytesPerSecond];
    
    NSUInteger desiredImageURLIdx;
    
    if (currentBytesPerSecond == -1) {
        // Base it on reachability
        switch ([[PINSpeedRecorder sharedRecorder] connectionStatus]) {
            case PINSpeedRecorderConnectionStatusWiFi:
                desiredImageURLIdx = urls.count - 1;
                break;
                
            case PINSpeedRecorderConnectionStatusWWAN:
            case PINSpeedRecorderConnectionStatusNotReachable:
                desiredImageURLIdx = 0;
                break;
        }
    } else {
        if (currentBytesPerSecond >= highQualityQPSThreshold) {
            desiredImageURLIdx = urls.count - 1;
        } else if (currentBytesPerSecond <= lowQualityQPSThreshold) {
            desiredImageURLIdx = 0;
        } else if (urls.count == 2) {
            desiredImageURLIdx = roundf((currentBytesPerSecond - lowQualityQPSThreshold) / ((highQualityQPSThreshold - lowQualityQPSThreshold) / (float)(urls.count - 1)));
        } else {
            desiredImageURLIdx = ceilf((currentBytesPerSecond - lowQualityQPSThreshold) / ((highQualityQPSThreshold - lowQualityQPSThreshold) / (float)(urls.count - 2)));
        }
    }
    
    return desiredImageURLIdx;
}

@end

@implementation PINTaskQOS

- (instancetype)initWithBPS:(float)bytesPerSecond endDate:(NSDate *)endDate
{
    if (self = [super init]) {
        self.endDate = endDate;
        self.bytesPerSecond = bytesPerSecond;
    }
    return self;
}

@end
