//
//  PINURLSessionManager.m
//  Pods
//
//  Created by Garrett Moon on 6/26/15.
//
//

#import "PINURLSessionManager.h"

#import "PINSpeedRecorder.h"

NSErrorDomain const PINURLErrorDomain = @"PINURLErrorDomain";

@interface PINURLSessionManager () <NSURLSessionDelegate, NSURLSessionDataDelegate>

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
    }
    return self;
}

- (void)invalidateSessionAndCancelTasks
{
    [self lock];
        [self.session invalidateAndCancel];
    [self unlock];
}

- (nonnull NSURLSessionDataTask *)dataTaskWithRequest:(nonnull NSURLRequest *)request
                                    completionHandler:(nonnull PINURLSessionDataTaskCompletion)completionHandler 
{
    return [self dataTaskWithRequest:request 
                            priority:PINRemoteImageManagerPriorityDefault
                   completionHandler:completionHandler];
}

- (nonnull NSURLSessionDataTask *)dataTaskWithRequest:(nonnull NSURLRequest *)request
                                             priority:(PINRemoteImageManagerPriority)priority
                                    completionHandler:(nonnull PINURLSessionDataTaskCompletion)completionHandler
{
    [self lock];
        NSURLSessionDataTask *dataTask = [self.session dataTaskWithRequest:request];
        if (@available(iOS 8.0, macOS 10.10, tvOS 9.0, watchOS 2.0, *)) {
            dataTask.priority = dataTaskPriorityWithImageManagerPriority(priority);
        }
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
        NSHTTPURLResponse *response = (NSHTTPURLResponse *)task.response;
        NSInteger statusCode = [response statusCode];
        //If a 404 response contains an image, we treat it as a successful request and return the image
        BOOL recoverable = [self responseRecoverableFrom404:response];
        if (statusCode >= 400 && recoverable == NO) {
            error = [NSError errorWithDomain:PINURLErrorDomain
                                        code:statusCode
                                    userInfo:@{NSLocalizedDescriptionKey : @"HTTP Error Response."}];
        }
    }
    __weak typeof(self) weakSelf = self;
    dispatch_async(delegateQueue, ^{
        typeof(self) strongSelf = weakSelf;
        
        [strongSelf lock];
            PINURLSessionDataTaskCompletion completionHandler = strongSelf.completions[@(task.taskIdentifier)];
            [strongSelf.completions removeObjectForKey:@(task.taskIdentifier)];
            [strongSelf.delegateQueues removeObjectForKey:@(task.taskIdentifier)];
        [strongSelf unlock];
        
        if (completionHandler) {
            completionHandler(task, error);
        }
        
        if ([strongSelf.delegate respondsToSelector:@selector(didCompleteTask:withError:)]) {
            [strongSelf.delegate didCompleteTask:task withError:error];
        }
    });
}

#pragma mark - session statistics

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didFinishCollectingMetrics:(NSURLSessionTaskMetrics *)metrics
{
    if (@available(iOS 10.0, macOS 10.12, *)) {
        [[PINSpeedRecorder sharedRecorder] processMetrics:metrics forTask:task];
        
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
            if ([strongSelf.delegate respondsToSelector:@selector(didCollectMetrics:forURL:)]) {
                [strongSelf.delegate didCollectMetrics:metrics forURL:task.originalRequest.URL];
            }
        });
    }
}

- (BOOL)responseRecoverableFrom404:(NSHTTPURLResponse*)response
{
    return response.statusCode == 404
        && [response.allHeaderFields[@"content-type"] rangeOfString:@"image"].location != NSNotFound;
}

#if DEBUG
- (void)concurrentDownloads:(void (^_Nullable)(NSUInteger concurrentDownloads))concurrentDownloadsCompletion
{
    if (@available(macos 10.11, iOS 9.0, watchOS 2.0, tvOS 9.0,  *)) {
        [self.session getAllTasksWithCompletionHandler:^(NSArray<__kindof NSURLSessionTask *> * _Nonnull tasks) {
            concurrentDownloadsCompletion(tasks.count);
        }];
    } else {
        [self.session getTasksWithCompletionHandler:^(NSArray<NSURLSessionDataTask *> * _Nonnull dataTasks,
                                                      NSArray<NSURLSessionUploadTask *> * _Nonnull uploadTasks,
                                                      NSArray<NSURLSessionDownloadTask *> * _Nonnull downloadTasks) {
          NSUInteger total = dataTasks.count + uploadTasks.count + downloadTasks.count;
          concurrentDownloadsCompletion(total);
        }];
    }
}

#endif

@end

