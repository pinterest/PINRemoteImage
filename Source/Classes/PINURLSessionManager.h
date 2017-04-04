//
//  PINURLSessionManager.h
//  Pods
//
//  Created by Garrett Moon on 6/26/15.
//
//

#import <Foundation/Foundation.h>

extern NSString * __nonnull const PINURLErrorDomain;

@protocol PINURLSessionManagerDelegate <NSObject>

@required
- (void)didReceiveData:(nonnull NSData *)data forTask:(nonnull NSURLSessionTask *)task;
- (void)didCompleteTask:(nonnull NSURLSessionTask *)task withError:(nullable NSError *)error;

@optional
- (void)didReceiveResponse:(nonnull NSURLResponse *)response forTask:(nonnull NSURLSessionTask *)task;
- (void)didReceiveAuthenticationChallenge:(nonnull NSURLAuthenticationChallenge *)challenge forTask:(nullable NSURLSessionTask *)task completionHandler:(nonnull void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential  * _Nullable credential))completionHandler;


@end

typedef void (^PINURLSessionDataTaskCompletion)(NSURLSessionTask * _Nonnull task, NSError * _Nullable error);

@interface PINURLSessionManager : NSObject

- (nonnull instancetype)initWithSessionConfiguration:(nullable NSURLSessionConfiguration *)configuration;

- (nonnull NSURLSessionDataTask *)dataTaskWithRequest:(nonnull NSURLRequest *)request completionHandler:(nonnull PINURLSessionDataTaskCompletion)completionHandler;

- (void)invalidateSessionAndCancelTasks;

@property (atomic, weak, nullable) id <PINURLSessionManagerDelegate> delegate;

#if DEBUG
- (void)concurrentDownloads:(void (^_Nullable)(NSUInteger concurrentDownloads))concurrentDownloadsCompletion;
#endif

@end
