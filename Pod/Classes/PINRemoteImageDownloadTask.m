//
//  PINRemoteImageDownloadTask.m
//  Pods
//
//  Created by Garrett Moon on 3/9/15.
//
//

#import "PINRemoteImageDownloadTask.h"

#import "PINRemoteImage.h"
#import "PINRemoteImageCallbacks.h"

@implementation PINRemoteImageDownloadTask

- (BOOL)hasProgressBlocks
{
    __block BOOL hasProgressBlocks = NO;
    [self.callbackBlocks enumerateKeysAndObjectsUsingBlock:^(NSUUID *UUID, PINRemoteImageCallbacks *callback, BOOL *stop) {
        if (callback.progressBlock) {
            hasProgressBlocks = YES;
            *stop = YES;
        }
    }];
    return hasProgressBlocks;
}

- (void)callProgressWithQueue:(dispatch_queue_t)queue withImage:(UIImage *)image
{
    [self.callbackBlocks enumerateKeysAndObjectsUsingBlock:^(NSUUID *UUID, PINRemoteImageCallbacks *callback, BOOL *stop) {
        if (callback.progressBlock != nil) {
            PINLog(@"calling progress for UUID: %@ key: %@", UUID, self.key);
            dispatch_async(queue, ^
            {
                callback.progressBlock([PINRemoteImageManagerResult imageResultWithImage:image
                                                                          animatedImage:nil
                                                                          requestLength:CACurrentMediaTime() - callback.requestTime
                                                                                  error:nil
                                                                             resultType:PINRemoteImageResultTypeProgress UUID:UUID]);
            });
        }
    }];
}

- (BOOL)cancelWithUUID:(NSUUID *)UUID manager:(PINRemoteImageManager *)manager
{
    BOOL noMoreCompletions = [super cancelWithUUID:UUID manager:manager];
    if (noMoreCompletions) {
        [self.urlSessionTaskOperation cancel];
        PINLog(@"Canceling download of URL: %@, UUID: %@", self.urlSessionTaskOperation.dataTask.originalRequest.URL, UUID);
    } else {
        PINLog(@"Decrementing download of URL: %@, UUID: %@", self.urlSessionTaskOperation.dataTask.originalRequest.URL, UUID);
    }
    return noMoreCompletions;
}

- (void)setPriority:(PINRemoteImageManagerPriority)priority
{
    [super setPriority:priority];
    self.urlSessionTaskOperation.dataTask.priority = dataTaskPriorityWithImageManagerPriority(priority);
    self.urlSessionTaskOperation.queuePriority = operationPriorityWithImageManagerPriority(priority);
}

@end
