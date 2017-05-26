//
//  PINURLSessionManager.m
//  Pods
//
//  Created by Garrett Moon on 6/26/15.
//
//

#import "PINURLSessionManager.h"

NSString * const PINURLErrorDomain = @"PINURLErrorDomain";

@interface PINURLSessionManager () <NSURLSessionDelegate, NSURLSessionDataDelegate>
{
    NSCache *_timeToFirstByteCache;
}

@property (nonatomic, strong) NSLock *sessionManagerLock;
@property (nonatomic, strong) NSURLSession *session;
@property (nonatomic, strong) NSOperationQueue *operationQueue;
@property (nonatomic, strong) NSMutableDictionary <NSNumber *, dispatch_queue_t> *delegateQueues;
@property (nonatomic, strong) NSMutableDictionary <NSNumber *, PINURLSessionDataTaskCompletion> *completions;

@end

@implementation PINURLSessionManager

- (instancetype)initWithSessionConfiguration:(NSURLSessionConfiguration *)configuration
{
    if (self = [super init]) {
        self.sessionManagerLock = [[NSLock alloc] init];
        self.sessionManagerLock.name = @"PINURLSessionManager";
        self.operationQueue = [[NSOperationQueue alloc] init];
        self.operationQueue.name = @"PINURLSessionManager Operation Queue";
        
        //queue must be serial to ensure proper ordering
        [self.operationQueue setMaxConcurrentOperationCount:1];
        self.session = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:self.operationQueue];
        self.completions = [[NSMutableDictionary alloc] init];
        self.delegateQueues = [[NSMutableDictionary alloc] init];
        
        _timeToFirstByteCache = [[NSCache alloc] init];
        _timeToFirstByteCache.countLimit = 25;
    }
    return self;
}

- (void)invalidateSessionAndCancelTasks
{
    [self lock];
        [self.session invalidateAndCancel];
    [self unlock];
}

- (nonnull NSURLSessionDataTask *)dataTaskWithRequest:(nonnull NSURLRequest *)request completionHandler:(nonnull PINURLSessionDataTaskCompletion)completionHandler
{
    [self lock];
        NSURLSessionDataTask *dataTask = [self.session dataTaskWithRequest:request];
        if (completionHandler) {
            [self.completions setObject:completionHandler forKey:@(dataTask.taskIdentifier)];
        }
        NSString *queueName = [NSString stringWithFormat:@"PINURLSessionManager delegate queue - %ld", (unsigned long)dataTask.taskIdentifier];
        dispatch_queue_t delegateQueue = dispatch_queue_create([queueName UTF8String], DISPATCH_QUEUE_SERIAL);
        [self.delegateQueues setObject:delegateQueue forKey:@(dataTask.taskIdentifier)];
    [self unlock];
    return dataTask;
}

- (void)lock
{
    [self.sessionManagerLock lock];
}

- (void)unlock
{
    [self.sessionManagerLock unlock];
}

#pragma mark NSURLSessionDataDelegate

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)task didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler
{
    [self lock];
        dispatch_queue_t delegateQueue = self.delegateQueues[@(task.taskIdentifier)];
    [self unlock];
    
    NSAssert(delegateQueue != nil, @"There seems to be an issue in iOS 9 where this can be nil. If you can reliably reproduce hitting this, *please* open an issue: https://github.com/pinterest/PINRemoteImage/issues");
    if (delegateQueue == nil) {
        return;
    }
    
    __weak typeof(self) weakSelf = self;
    dispatch_async(delegateQueue, ^{
        typeof(self) strongSelf = weakSelf;
        if ([strongSelf.delegate respondsToSelector:@selector(didReceiveResponse:forTask:)]) {
            [strongSelf.delegate didReceiveResponse:response forTask:task];
        }
    });
    //Even though this is documented to be non-nil, in the wild it sometimes is.
    if (completionHandler) {
        completionHandler(NSURLSessionResponseAllow);
    }
}

- (void)URLSession:(NSURLSession *)session didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *credential))completionHandler
{
    if ([self.delegate respondsToSelector:@selector(didReceiveAuthenticationChallenge:forTask:completionHandler:)]) {
        [self.delegate didReceiveAuthenticationChallenge:challenge forTask:nil completionHandler:completionHandler];
    } else {
        //Even though this is documented to be non-nil, in the wild it sometimes is.
        if (completionHandler) {
            completionHandler(NSURLSessionAuthChallengePerformDefaultHandling, nil);
        }
    }
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *credential))completionHandler 
{
    [self lock];
        dispatch_queue_t delegateQueue = self.delegateQueues[@(task.taskIdentifier)];
    [self unlock];
    
    NSAssert(delegateQueue != nil, @"There seems to be an issue in iOS 9 where this can be nil. If you can reliably reproduce hitting this, *please* open an issue: https://github.com/pinterest/PINRemoteImage/issues");
    if (delegateQueue == nil) {
        return;
    }

    __weak typeof(self) weakSelf = self;
    dispatch_async(delegateQueue, ^{
        typeof(self) strongSelf = weakSelf;
        if ([strongSelf.delegate respondsToSelector:@selector(didReceiveAuthenticationChallenge:forTask:completionHandler:)]) {
            [strongSelf.delegate didReceiveAuthenticationChallenge:challenge forTask:task completionHandler:completionHandler];
        } else {
            //Even though this is documented to be non-nil, in the wild it sometimes is
            if (completionHandler) {
                completionHandler(NSURLSessionAuthChallengePerformDefaultHandling, nil);
            }
        }
    });
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)task didReceiveData:(NSData *)data
{
    [self lock];
        dispatch_queue_t delegateQueue = self.delegateQueues[@(task.taskIdentifier)];
    [self unlock];
    
    NSAssert(delegateQueue != nil, @"There seems to be an issue in iOS 9 where this can be nil. If you can reliably reproduce hitting this, *please* open an issue: https://github.com/pinterest/PINRemoteImage/issues");
    if (delegateQueue == nil) {
        return;
    }
    
    __weak typeof(self) weakSelf = self;
    dispatch_async(delegateQueue, ^{
        typeof(self) strongSelf = weakSelf;
        [strongSelf.delegate didReceiveData:data forTask:task];
    });
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
    [self lock];
        dispatch_queue_t delegateQueue = self.delegateQueues[@(task.taskIdentifier)];
    [self unlock];
    
    NSAssert(delegateQueue != nil, @"There seems to be an issue in iOS 9 where this can be nil. If you can reliably reproduce hitting this, *please* open an issue: https://github.com/pinterest/PINRemoteImage/issues");
    if (delegateQueue == nil) {
        return;
    }
    
    if (!error && [task.response isKindOfClass:[NSHTTPURLResponse class]]) {
        NSInteger statusCode = [(NSHTTPURLResponse *)task.response statusCode];
        if (statusCode >= 400) {
            error = [NSError errorWithDomain:PINURLErrorDomain
                                        code:statusCode
                                    userInfo:@{NSLocalizedDescriptionKey : @"HTTP Error Response."}];
        }
    }
    __weak typeof(self) weakSelf = self;
    dispatch_async(delegateQueue, ^{
        typeof(self) strongSelf = weakSelf;
        [strongSelf.delegate didCompleteTask:task withError:error];
        
        [strongSelf lock];
            PINURLSessionDataTaskCompletion completionHandler = strongSelf.completions[@(task.taskIdentifier)];
            [strongSelf.completions removeObjectForKey:@(task.taskIdentifier)];
            [strongSelf.delegateQueues removeObjectForKey:@(task.taskIdentifier)];
        [strongSelf unlock];
        
        if (completionHandler) {
            completionHandler(task, error);
        }
    });
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didFinishCollectingMetrics:(NSURLSessionTaskMetrics *)metrics
{
    NSDate *requestStart = [NSDate distantFuture];
    NSDate *firstByte = [NSDate distantPast];
    
    for (NSURLSessionTaskTransactionMetrics *metric in metrics.transactionMetrics) {
        if (metric.requestStartDate == nil || metric.responseStartDate == nil) {
            //Only evaluate requests which completed their first byte.
            return;
        }
        if ([requestStart compare:metric.requestStartDate] != NSOrderedAscending) {
            requestStart = metric.requestStartDate;
        }
        if ([firstByte compare:metric.responseStartDate] != NSOrderedDescending) {
            firstByte = metric.responseStartDate;
        }
    }
    
    [self storeTimeToFirstByte:[firstByte timeIntervalSinceDate:requestStart] forHost:task.originalRequest.URL.host];
}

/* We don't bother locking around the timeToFirstByteCache because NSCache itself is
 threadsafe and we're not concerned about dropping or overwriting a result. */
- (void)storeTimeToFirstByte:(NSTimeInterval)timeToFirstByte forHost:(NSString *)host
{
    NSNumber *existingTimeToFirstByte = [_timeToFirstByteCache objectForKey:host];
    if (existingTimeToFirstByte) {
        //We're obviously seriously weighting the latest result by doing this. Seems reasonable in
        //possibly changing network conditions.
        existingTimeToFirstByte = @( (timeToFirstByte + [existingTimeToFirstByte doubleValue]) / 2.0 );
    } else {
        existingTimeToFirstByte = [NSNumber numberWithDouble:timeToFirstByte];
    }
    [_timeToFirstByteCache setObject:existingTimeToFirstByte forKey:host];
}

- (NSTimeInterval)weightedTimeToFirstByteForHost:(NSString *)host
{
    NSTimeInterval timeToFirstByte;
    timeToFirstByte = [[_timeToFirstByteCache objectForKey:host] doubleValue];
    if (timeToFirstByte <= 0 + DBL_EPSILON) {
        //return 0 if we're not sure.
        timeToFirstByte = 0;
    }
    return timeToFirstByte;
}

#if DEBUG
- (void)concurrentDownloads:(void (^_Nullable)(NSUInteger concurrentDownloads))concurrentDownloadsCompletion
{
    [self.session getAllTasksWithCompletionHandler:^(NSArray<__kindof NSURLSessionTask *> * _Nonnull tasks) {
        concurrentDownloadsCompletion(tasks.count);
    }];
}

#endif

@end
