//
//  PINDataTaskOperation.h
//  Pods
//
//  Created by Garrett Moon on 3/12/15.
//
//

#import <Foundation/Foundation.h>

#import "PINURLSessionManager.h"

@interface PINDataTaskOperation : NSOperation

@property (nonatomic, readonly) NSURLSessionDataTask *dataTask;

+ (instancetype)dataTaskOperationWithSessionManager:(PINURLSessionManager *)sessionManager
                                            request:(NSURLRequest *)request
                                  completionHandler:(void (^)(NSURLResponse *response, NSError *error))completionHandler;

@end
