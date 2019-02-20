//
//  PINRemoteImageDownloadTask.m
//  Pods
//
//  Created by Garrett Moon on 3/9/15.
//
//

#import "PINRemoteImageDownloadTask.h"

#import "PINRemoteImageTask+Subclassing.h"
#import "PINRemoteImage.h"
#import "PINRemoteImageCallbacks.h"
#import "PINRemoteLock.h"
#import "PINSpeedRecorder.h"

@interface PINRemoteImageDownloadTask ()
{
    PINProgressiveImage *_progressImage;
    PINResume *_resume;
    id<PINRequestRetryStrategy> _retryStrategy;
}

@end

@implementation PINRemoteImageDownloadTask

- (instancetype)initWithManager:(PINRemoteImageManager *)manager
{
    if (self = [super initWithManager:manager]) {
        _retryStrategy = manager.retryStrategyCreationBlock();
    }
    return self;
}

- (void)callProgressDownload
{
    NSDictionary *callbackBlocks = self.callbackBlocks;
    #if PINRemoteImageLogging
    NSString *key = self.key;
    #endif
    
    __block int64_t completedBytes;
    __block int64_t totalBytes;
    
    [self.lock lockWithBlock:^{
        completedBytes = self->_progressImage.dataTask.countOfBytesReceived;
        totalBytes = self->_progressImage.dataTask.countOfBytesExpectedToReceive;
    }];
    
    [callbackBlocks enumerateKeysAndObjectsUsingBlock:^(NSUUID *UUID, PINRemoteImageCallbacks *callback, BOOL *stop) {
        PINRemoteImageManagerProgressDownload progressDownloadBlock = callback.progressDownloadBlock;
        if (progressDownloadBlock != nil) {
            PINLog(@"calling progress for UUID: %@ key: %@", UUID, key);
            dispatch_async(self.manager.callbackQueue, ^
            {
                progressDownloadBlock(completedBytes, totalBytes);
            });
        }
    }];
}

- (void)callProgressImageWithImage:(nonnull PINImage *)image renderedImageQuality:(CGFloat)renderedImageQuality
{
    NSDictionary *callbackBlocks = self.callbackBlocks;
#if PINRemoteImageLogging
    NSString *key = self.key;
#endif
    
    
    [callbackBlocks enumerateKeysAndObjectsUsingBlock:^(NSUUID *UUID, PINRemoteImageCallbacks *callback, BOOL *stop) {
        PINRemoteImageManagerImageCompletion progressImageBlock = callback.progressImageBlock;
        if (progressImageBlock != nil) {
            PINLog(@"calling progress for UUID: %@ key: %@", UUID, key);
            CFTimeInterval requestTime = callback.requestTime;

            dispatch_async(self.manager.callbackQueue, ^
            {
                progressImageBlock([PINRemoteImageManagerResult imageResultWithImage:image
                                                           alternativeRepresentation:nil
                                                                       requestLength:CACurrentMediaTime() - requestTime
                                                                          resultType:PINRemoteImageResultTypeProgress
                                                                                UUID:UUID
                                                                            response:nil
                                                                               error:nil
                                                                renderedImageQuality:renderedImageQuality]);
           });
        }
    }];
}

- (BOOL)cancelWithUUID:(NSUUID *)UUID resume:(PINResume **)resume
{
    __block BOOL noMoreCompletions;
    __block PINResume *strongResume;
    BOOL hasResume = resume != nil;
    [self.lock lockWithBlock:^{
        if (hasResume) {
            //consider skipping cancelation if there's a request for resume data and the time to start the connection is greater than
            //the time remaining to download.
            NSTimeInterval timeToFirstByte = [[PINSpeedRecorder sharedRecorder] weightedTimeToFirstByteForHost:self->_progressImage.dataTask.currentRequest.URL.host];
            if (self->_progressImage.estimatedRemainingTime <= timeToFirstByte) {
                noMoreCompletions = NO;
                return;
            }
        }
        
        noMoreCompletions = [super l_cancelWithUUID:UUID];
        
        if (noMoreCompletions) {
            [self.manager.urlSessionTaskQueue removeDownloadTaskFromQueue:self->_progressImage.dataTask];
            [self->_progressImage.dataTask cancel];
            
            if (hasResume && self->_ifRange && self->_progressImage.dataTask.countOfBytesExpectedToReceive > 0 && self->_progressImage.dataTask.countOfBytesExpectedToReceive != NSURLSessionTransferSizeUnknown) {
                NSData *progressData = self->_progressImage.data;
                if (progressData.length > 0) {
                    strongResume = [PINResume resumeData:progressData ifRange:self->_ifRange totalBytes:self->_progressImage.dataTask.countOfBytesExpectedToReceive];
                }
            }
            
            PINLog(@"Canceling download of URL: %@, UUID: %@", _progressImage.dataTask.originalRequest.URL, UUID);
        }
#if PINRemoteImageLogging
        else {
            PINLog(@"Decrementing download of URL: %@, UUID: %@", _progressImage.dataTask.originalRequest.URL, UUID);
        }
#endif
    }];
    
    if (hasResume) {
        *resume = strongResume;
    }
    
    return noMoreCompletions;
}

- (void)setPriority:(PINRemoteImageManagerPriority)priority
{
    [super setPriority:priority];
    if (@available(iOS 8.0, macOS 10.10, tvOS 9.0, watchOS 2.0, *)) {
        [self.lock lockWithBlock:^{
            NSURLSessionDataTask *dataTask = self->_progressImage.dataTask;
            if (dataTask) {
                dataTask.priority = dataTaskPriorityWithImageManagerPriority(priority);
                [self.manager.urlSessionTaskQueue setQueuePriority:priority forTask:dataTask];
            }
        }];
    }
}

- (NSURL *)URL
{
    __block NSURL *url;
    [self.lock lockWithBlock:^{
        url = self->_progressImage.dataTask.originalRequest.URL;
    }];
    return url;
}

- (nonnull PINRemoteImageManagerResult *)imageResultWithImage:(nullable PINImage *)image
                                    alternativeRepresentation:(nullable id)alternativeRepresentation
                                                requestLength:(NSTimeInterval)requestLength
                                                        error:(nullable NSError *)error
                                                   resultType:(PINRemoteImageResultType)resultType
                                                         UUID:(nullable NSUUID *)UUID
                                                     response:(nonnull NSURLResponse *)response
{
    __block NSUInteger bytesSavedByResuming;
    [self.lock lockWithBlock:^{
        bytesSavedByResuming = self->_resume.resumeData.length;
    }];
    return [PINRemoteImageManagerResult imageResultWithImage:image
                                   alternativeRepresentation:alternativeRepresentation
                                               requestLength:requestLength
                                                  resultType:resultType
                                                        UUID:UUID
                                                    response:response
                                                       error:error
                                        bytesSavedByResuming:bytesSavedByResuming];
}

- (void)didReceiveData:(NSData *_Nonnull)data
{
    [self callProgressDownload];
    
    __block int64_t expectedNumberOfBytes;
    [self.lock lockWithBlock:^{
        expectedNumberOfBytes = self->_progressImage.dataTask.countOfBytesExpectedToReceive;
    }];
    
    [self updateData:data isResume:NO expectedBytes:expectedNumberOfBytes];
}

- (void)updateData:(NSData *)data isResume:(BOOL)isResume expectedBytes:(int64_t)expectedBytes
{
    __block PINProgressiveImage *progressImage;
    __block BOOL hasProgressBlocks = NO;
    [self.lock lockWithBlock:^{
        progressImage = self->_progressImage;
        [[self l_callbackBlocks] enumerateKeysAndObjectsUsingBlock:^(NSUUID *UUID, PINRemoteImageCallbacks *callback, BOOL *stop) {
            if (callback.progressImageBlock) {
                hasProgressBlocks = YES;
                *stop = YES;
            }
        }];
    }];
    
    [progressImage updateProgressiveImageWithData:data expectedNumberOfBytes:expectedBytes isResume:isResume];
    
    if (hasProgressBlocks) {
        if (PINNSOperationSupportsBlur) {
            [self.manager.concurrentOperationQueue scheduleOperation:^{
                CGFloat renderedImageQuality = 1.0;
                PINImage *image = [progressImage currentImageBlurred:self.manager.shouldBlurProgressive maxProgressiveRenderSize:self.manager.maxProgressiveRenderSize renderedImageQuality:&renderedImageQuality];
                if (image) {
                    [self callProgressImageWithImage:image renderedImageQuality:renderedImageQuality];
                }
            } withPriority:PINOperationQueuePriorityLow];
        }
    }
}

- (void)didReceiveResponse:(nonnull NSURLResponse *)response
{
    if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        
        // Got partial data back for a resume
        if (httpResponse.statusCode == 206) {
            __block PINResume *resume;
            [self.lock lockWithBlock:^{
                resume = self->_resume;
            }];
            
            [self updateData:resume.resumeData isResume:YES expectedBytes:resume.totalBytes];
        } else {
            //Check if there's resume data and we didn't get back a 206, get rid of it
            [self.lock lockWithBlock:^{
                self->_resume = nil;
            }];
        }
        
        // Check to see if the server supports resume
        if ([[httpResponse allHeaderFields][@"Accept-Ranges"] isEqualToString:@"bytes"]) {
            NSString *ifRange = nil;
            NSString *etag = nil;
            
            if ((etag = [httpResponse allHeaderFields][@"ETag"])) {
                if ([etag hasPrefix:@"W/"] == NO) {
                    ifRange = etag;
                }
            } else {
                ifRange = [httpResponse allHeaderFields][@"Last-Modified"];
            }
            
            if (ifRange.length > 0) {
                [self.lock lockWithBlock:^{
                    self->_ifRange = ifRange;
                }];
            }
        }
    }
}

- (void)scheduleDownloadWithRequest:(nonnull NSURLRequest *)request
                             resume:(nullable PINResume *)resume
                          skipRetry:(BOOL)skipRetry
                           priority:(PINRemoteImageManagerPriority)priority
                  completionHandler:(nonnull PINRemoteImageManagerDataCompletion)completionHandler
{
  [self scheduleDownloadWithRequest:request resume:resume skipRetry:skipRetry priority:priority isRetry:NO completionHandler:completionHandler];
}

- (void)scheduleDownloadWithRequest:(NSURLRequest *)request
                             resume:(PINResume *)resume
                          skipRetry:(BOOL)skipRetry
                           priority:(PINRemoteImageManagerPriority)priority
                            isRetry:(BOOL)isRetry
                  completionHandler:(PINRemoteImageManagerDataCompletion)completionHandler
{
    [self.lock lockWithBlock:^{
        if (self->_progressImage != nil || [self l_callbackBlocks].count == 0 || (isRetry == NO && self->_retryStrategy.numberOfRetries > 0)) {
            return;
        }
        self->_resume = resume;
        
        NSURLRequest *adjustedRequest = request;
        if (self->_resume) {
            NSMutableURLRequest *mutableRequest = [request mutableCopy];
            NSMutableDictionary *headers = [[mutableRequest allHTTPHeaderFields] mutableCopy];
            headers[@"If-Range"] = self->_resume.ifRange;
            headers[@"Range"] = [NSString stringWithFormat:@"bytes=%tu-", self->_resume.resumeData.length];
            mutableRequest.allHTTPHeaderFields = headers;
            adjustedRequest = mutableRequest;
        }
        
        self->_progressImage = [[PINProgressiveImage alloc] initWithDataTask:[self.manager.urlSessionTaskQueue addDownloadWithSessionManager:self.manager.sessionManager
                                                                                                                                     request:adjustedRequest
                                                                                                                                    priority:priority
                                                                                                                           completionHandler:^(NSURLResponse * _Nonnull response, NSError * _Nonnull remoteError)
        {
            [self.manager.concurrentOperationQueue scheduleOperation:^{
                NSError *error = remoteError;
#if PINRemoteImageLogging
                if (error && error.code != NSURLErrorCancelled) {
                    PINLog(@"Failed downloading image: %@ with error: %@", request.URL, error);
                } else if (error == nil && response.expectedContentLength == 0) {
                    PINLog(@"image is empty at URL: %@", request.URL);
                } else {
                    PINLog(@"Finished downloading image: %@", request.URL);
                }
#endif
                
                if (error.code != NSURLErrorCancelled) {
                    NSData *data = self.progressImage.data;
                    
                    if (error == nil && data == nil) {
                        error = [NSError errorWithDomain:PINRemoteImageManagerErrorDomain
                                                    code:PINRemoteImageManagerErrorImageEmpty
                                                userInfo:nil];
                    }
                    
                    __block BOOL retry = NO;
                    __block int64_t delay = 0;
                    [self.lock lockWithBlock:^{
                        retry = skipRetry == NO && [self->_retryStrategy shouldRetryWithError:error];
                        if (retry) {
                            // Clear out the existing progress image or else new data from retry will be appended
                            self->_progressImage = nil;
                            [self->_retryStrategy incrementRetryCount];
                            delay = [self->_retryStrategy nextDelay];
                        }
                    }];
                    if (retry) {
                        PINLog(@"Retrying download of %@ in %lld seconds.", request.URL, delay);
                        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                            [self scheduleDownloadWithRequest:request resume:nil skipRetry:skipRetry priority:priority isRetry:YES completionHandler:completionHandler];
                        });
                        return;
                    }
                    
                    completionHandler(data, response, error);
                }
            }];
        }]];
    }];
}

- (PINProgressiveImage *)progressImage
{
    __block PINProgressiveImage *progressImage = nil;
    [self.lock lockWithBlock:^{
        progressImage = self->_progressImage;
    }];
    return progressImage;
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

- (CFTimeInterval)estimatedRemainingTime
{
    return self.progressImage.estimatedRemainingTime;
}

- (NSData *)data
{
    return self.progressImage.data;
}

@end
