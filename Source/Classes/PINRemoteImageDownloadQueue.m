//
//  PINRemoteImageDownloadQueue.m
//  PINRemoteImage
//
//  Created by Garrett Moon on 3/1/17.
//  Copyright © 2017 Pinterest. All rights reserved.
//

#import "PINRemoteImageDownloadQueue.h"

#import "PINURLSessionManager.h"
#import "PINRemoteLock.h"

@interface PINRemoteImageDownloadQueue ()
{
    NSUInteger _runningOperationCount;
    PINRemoteLock *_lock;
    
    NSMutableArray <NSURLSessionDataTask *> *_highPriorityQueuedOperations;
    NSMutableArray <NSURLSessionDataTask *> *_defaultPriorityQueuedOperations;
    NSMutableArray <NSURLSessionDataTask *> *_lowPriorityQueuedOperations;
}

@end

@implementation PINRemoteImageDownloadQueue

@synthesize maximumNumberOfOperations = _maximumNumberOfOperations;

- (PINRemoteImageDownloadQueue *)initWithMaximumNumberOfOperations:(NSUInteger)maximumNumberOfOperations
{
    if (self = [super init]) {
        _maximumNumberOfOperations = maximumNumberOfOperations;
        
        _lock = [[PINRemoteLock alloc] initWithName:@"PINRemoteImageDownloadQueue Lock"];
        _highPriorityQueuedOperations = [[NSMutableArray alloc] init];
        _defaultPriorityQueuedOperations = [[NSMutableArray alloc] init];
        _lowPriorityQueuedOperations = [[NSMutableArray alloc] init];
    }
    return self;
}

- (NSUInteger)maximumNumberOfOperations
{
    [self lock];
        NSUInteger maximumNumberOfOperations = _maximumNumberOfOperations;
    [self unlock];
    return maximumNumberOfOperations;
}

- (void)setMaximumNumberOfOperations:(NSUInteger)maximumNumberOfOperations
{
    [self lock];
        _maximumNumberOfOperations = maximumNumberOfOperations;
    [self unlock];
}

- (NSURLSessionDataTask *)addDownloadWithSessionManager:(PINURLSessionManager *)sessionManager
                                                request:(NSURLRequest *)request
                                               priority:(PINRemoteImageManagerPriority)priority
                                      completionHandler:(PINRemoteImageDownloadCompletion)completionHandler
{
    NSURLSessionDataTask *dataTask = [sessionManager dataTaskWithRequest:request completionHandler:^(NSURLResponse *response, NSError *error) {
        completionHandler(response, error);
        [self lock];
            _runningOperationCount--;
        [self unlock];
        
        [self scheduleDownloadsIfNeeded];
    }];
    
    [self setTaskQueuePriority:dataTask priority:priority];
    
    [self scheduleDownloadsIfNeeded];
    
    return dataTask;
}

- (void)scheduleDownloadsIfNeeded
{
    [self lock];
        if (_runningOperationCount < _maximumNumberOfOperations) {
            NSMutableArray <NSURLSessionDataTask *> *queue = nil;
            if (_highPriorityQueuedOperations.count > 0) {
                [_highPriorityQueuedOperations removeObjectAtIndex:0];
            } else if (_defaultPriorityQueuedOperations.count > 0) {
                queue = _defaultPriorityQueuedOperations;
            } else if (_lowPriorityQueuedOperations.count > 0) {
                queue = _lowPriorityQueuedOperations;
            }
            
            if (queue) {
                NSURLSessionDataTask *task = [queue firstObject];
                [queue removeObjectAtIndex:0];
                [task resume];
                
                _runningOperationCount++;
            }
        }
    [self unlock];
}

- (void)dequeueDownload:(NSURLSessionDataTask *)downloadTask
{
    [self lock];
        [_highPriorityQueuedOperations removeObject:downloadTask];
        [_defaultPriorityQueuedOperations removeObject:downloadTask];
        [_lowPriorityQueuedOperations removeObject:downloadTask];
    [self unlock];
}

- (void)setTaskQueuePriority:(NSURLSessionDataTask *)downloadTask priority:(PINRemoteImageManagerPriority)priority
{
    [self dequeueDownload:downloadTask];
    
    NSMutableArray <NSURLSessionDataTask *> *queue = nil;
    [self lock];
        switch (priority) {
            case PINRemoteImageManagerPriorityLow:
                queue = _lowPriorityQueuedOperations;
                break;
                
            case PINRemoteImageManagerPriorityDefault:
                queue = _defaultPriorityQueuedOperations;
                break;
                
            case PINRemoteImageManagerPriorityHigh:
                queue = _highPriorityQueuedOperations;
                break;
        }
        [queue addObject:downloadTask];
    [self unlock];
}

- (void)lock
{
    [_lock lock];
}

- (void)unlock
{
    [_lock unlock];
}

@end
