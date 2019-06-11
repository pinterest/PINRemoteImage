//
//  PINURLSessionManager.h
//  Pods
//
//  Created by Garrett Moon on 6/26/15.
//
//

#import <Foundation/Foundation.h>

#import "PINRemoteImageManager.h"

extern NSErrorDomain _Nonnull const PINURLErrorDomain;

@protocol PINURLSessionManagerDelegate <NSObject>

@required
- (void)didReceiveData:(nonnull NSData *)data forTask:(nonnull NSURLSessionTask *)task;

@optional
- (void)didCollectMetrics:(nonnull NSURLSessionTaskMetrics *)metrics forURL:(nonnull NSURL *)url API_AVAILABLE(macosx(10.12), ios(10.0), watchos(3.0), tvos(10.0));
- (void)didReceiveResponse:(nonnull NSURLResponse *)response forTask:(nonnull NSURLSessionTask *)task;
- (void)didReceiveAuthenticationChallenge:(nonnull NSURLAuthenticationChallenge *)challenge forTask:(nullable NSURLSessionTask *)task completionHandler:(nonnull void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential  * _Nullable credential))completionHandler;


@end

typedef void (^PINURLSessionDataTaskCompletion)(NSURLSessionTask * _Nonnull task, NSError * _Nullable error);

@interface PINURLSessionManager : NSObject

- (nonnull instancetype)initWithSessionConfiguration:(nullable NSURLSessionConfiguration *)configuration;

- (nonnull NSURLSessionDataTask *)dataTaskWithRequest:(nonnull NSURLRequest *)request
                                    completionHandler:(nonnull PINURLSessionDataTaskCompletion)completionHandler;

- (nonnull NSURLSessionDataTask *)dataTaskWithRequest:(nonnull NSURLRequest *)request
                                             priority:(PINRemoteImageManagerPriority)priority
                                    completionHandler:(nonnull PINURLSessionDataTaskCompletion)completionHandler;

- (void)invalidateSessionAndCancelTasks;

- (void)URLSession:(nonnull NSURLSession *)session task:(nonnull NSURLSessionTask *)task didFinishCollectingMetrics:(nonnull NSURLSessionTaskMetrics *)metrics API_AVAILABLE(macosx(10.12), ios(10.0), watchos(3.0), tvos(10.0));

@property (atomic, weak, nullable) id <PINURLSessionManagerDelegate> delegate;

#if DEBUG
- (void)concurrentDownloads:(void (^_Nullable)(NSUInteger concurrentDownloads))concurrentDownloadsCompletion;
#endif

@end
