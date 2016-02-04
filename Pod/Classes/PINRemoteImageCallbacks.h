//
//  PINRemoteImageCallbacks.h
//  Pods
//
//  Created by Garrett Moon on 3/9/15.
//
//

#import <Foundation/Foundation.h>

#import "PINRemoteImageManager.h"

@interface PINRemoteImageCallbacks : NSObject

@property (nonatomic, strong, nullable) PINRemoteImageManagerImageCompletion completionBlock;
@property (nonatomic, strong, nullable) PINRemoteImageManagerImageCompletion progressBlock;
@property (nonatomic, assign) CFTimeInterval requestTime;

@end
