//
//  PINRemoteImageDownloadTask.h
//  Pods
//
//  Created by Garrett Moon on 3/9/15.
//
//

#if SWIFT_PACKAGE
@import PINOperation;
#else
#import "external/PINOperation/Source/PINOperation.h"
#endif

#import "PINRemoteImageManager+Private.h"
#import "Source/Classes/PINRemoteImageTask.h"
#import "Source/Classes/include/PINProgressiveImage.h"
#import "Source/Classes/PINResume.h"

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
