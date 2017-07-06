//
//  PINRequestRetryStrategy.h
//  Pods
//
//  Created by Hovhannes Safaryan on 9/24/16.
//
//

#import <Foundation/Foundation.h>

/*
 Decide whether request should be retried based on the error.
 **/

@protocol PINRequestRetryStrategy

- (BOOL)shouldRetryWithError:(NSError *)error;
- (int)nextDelay;
- (void)incrementRetryCount;
- (int)numberOfRetries;

@end

@interface PINRequestExponentialRetryStrategy : NSObject<PINRequestRetryStrategy>

- (instancetype)initWithRetryMaxCount:(int)retryMaxCount delayBase:(int)delayBase;

@end
