//
//  PINURLSessionManager.h
//  Pods
//
//  Created by Garrett Moon on 6/26/15.
//
//

#import <Foundation/Foundation.h>

@protocol PINURLSessionManagerDelegate <NSObject>

@required
- (void)didReceiveData:(NSData *)data forTask:(NSURLSessionTask *)task;
- (void)didCompleteTask:(NSURLSessionTask *)task withError:(NSError *)error;

@optional
- (void)didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge forTask:(NSURLSessionTask *)task completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *credential))completionHandler;


@end

@interface PINURLSessionManager : NSObject

- (instancetype)initWithSessionConfiguration:(NSURLSessionConfiguration *)configuration;

- (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request completionHandler:(void (^)(NSURLResponse *response, NSError *error))completionHandler;

- (void)invalidateSessionAndCancelTasks;

@property (atomic, weak) id <PINURLSessionManagerDelegate> delegate;

@end
