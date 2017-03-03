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

typedef void (^PINRemoteImageDownloadCompletion)(NSURLResponse *response, NSError *error);

@interface PINRemoteImageDownloadQueue : NSObject

@property (nonatomic, assign) NSUInteger maximumNumberOfOperations;

- (instancetype)init NS_UNAVAILABLE;
- (PINRemoteImageDownloadQueue *)initWithMaximumNumberOfOperations:(NSUInteger)maximumNumberOfOperations NS_DESIGNATED_INITIALIZER;

- (NSURLSessionDataTask *)addDownloadWithSessionManager:(PINURLSessionManager *)sessionManager
                                                request:(NSURLRequest *)request
                                               priority:(PINRemoteImageManagerPriority)priority
                                      completionHandler:(PINRemoteImageDownloadCompletion)completionHandler;

- (void)dequeueDownload:(NSURLSessionDataTask *)downloadTask;

- (void)setTaskQueuePriority:(NSURLSessionDataTask *)downloadTask priority:(PINRemoteImageManagerPriority)priority;

NS_ASSUME_NONNULL_END

@end
