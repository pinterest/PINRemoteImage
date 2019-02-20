//
//  PINRemoteImageDownloadQueue.h
//  PINRemoteImage
//
//  Created by Garrett Moon on 3/1/17.
//  Copyright © 2017 Pinterest. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "PINRemoteImageManager.h"

@class PINURLSessionManager;

NS_ASSUME_NONNULL_BEGIN

typedef void (^PINRemoteImageDownloadCompletion)(NSURLResponse * _Nullable response, NSError *error);

@interface PINRemoteImageDownloadQueue : NSObject

@property (atomic, assign) NSUInteger maxNumberOfConcurrentDownloads;

- (instancetype)init NS_UNAVAILABLE;
+ (PINRemoteImageDownloadQueue *)queueWithMaxConcurrentDownloads:(NSUInteger)maxNumberOfConcurrentDownloads;

- (NSURLSessionDataTask *)addDownloadWithSessionManager:(PINURLSessionManager *)sessionManager
                                                request:(NSURLRequest *)request
                                               priority:(PINRemoteImageManagerPriority)priority
                                      completionHandler:(PINRemoteImageDownloadCompletion)completionHandler;

/***
 This prevents a task from being run if it hasn't already started yet. It is the caller's responsibility to cancel
 the task if it has already been started.
 
 @return BOOL Returns YES if the task was in the queue. 
 */
- (BOOL)removeDownloadTaskFromQueue:(NSURLSessionDataTask *)downloadTask;

/*
 This sets the tasks priority of execution. It is the caller's responsibility to set the priority on the task itself
 for NSURLSessionManager.
 */
- (void)setQueuePriority:(PINRemoteImageManagerPriority)priority forTask:(NSURLSessionDataTask *)downloadTask;

NS_ASSUME_NONNULL_END

@end
