//
//  PINRequestRetryStrategy.m
//  Pods
//
//  Created by Hovhannes Safaryan on 9/24/16.
//
//

#import "PINRequestRetryStrategy.h"
#import "PINURLSessionManager.h"
#import "PINRemoteImageManager.h"

@interface PINRequestExponentialRetryStrategy ()

@property (nonatomic, assign) int retryMaxCount;
@property (nonatomic, assign) int retryCount;
@property (nonatomic, assign) int delayBase;

@end

@implementation PINRequestExponentialRetryStrategy

- (instancetype)initWithRetryMaxCount:(int)retryMaxCount delayBase:(int)delayBase
{
    if (self = [super init]) {
        _retryCount = 0;
        _retryMaxCount = retryMaxCount;
        _delayBase = delayBase;
    }
    return self;
}

- (int)numberOfRetries
{
    return self.retryCount;
}

- (BOOL)shouldRetryWithError:(NSError *)error
{
    if (error == nil || ![[self class] retriableError:error] ||
        self.retryCount >= self.retryMaxCount) {
        return NO;
    }
    return YES;
}

- (int)nextDelay
{
    return powf(self.delayBase, self.retryCount);
}

- (void)incrementRetryCount
{
    self.retryCount++;
}

+ (BOOL)retriableError:(NSError *)remoteImageError
{
    if ([remoteImageError.domain isEqualToString:PINURLErrorDomain]) {
        return remoteImageError.code >= 500;
    } else if ([remoteImageError.domain isEqualToString:NSURLErrorDomain] && remoteImageError.code == NSURLErrorUnsupportedURL) {
        return NO;
    } else if ([remoteImageError.domain isEqualToString:PINRemoteImageManagerErrorDomain]) {
        return NO;
    }
    return YES;
}

@end
