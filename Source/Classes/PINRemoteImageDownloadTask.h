//
//  PINRemoteImageDownloadTask.h
//  Pods
//
//  Created by Garrett Moon on 3/9/15.
//
//

#import <PINOperation/PINOperation.h>

#import "PINRemoteImageManager+Private.h"
#import "PINRemoteImageTask.h"
#import "PINProgressiveImage.h"
#import "PINResume.h"

@interface PINRemoteImageDownloadTask : PINRemoteImageTask

@property (nonatomic, strong, nullable, readonly) NSURL *URL;
@property (nonatomic, copy, nullable) NSString *ifRange;
@property (nonatomic, copy, readonly, nullable) NSData *data;

@property (nonatomic, readonly) CFTimeInterval estimatedRemainingTime;

- (void)scheduleDownloadWithRequest:(nonnull NSURLRequest *)request
                             resume:(nullable PINResume *)resume
                          skipRetry:(BOOL)skipRetry
                           priority:(PINRemoteImageManagerPriority)priority
                  completionHandler:(nonnull PINRemoteImageManagerDataCompletion)completionHandler;

- (void)didReceiveData:(nonnull NSData *)data;
- (void)didReceiveResponse:(nonnull NSURLResponse *)response;

@end
