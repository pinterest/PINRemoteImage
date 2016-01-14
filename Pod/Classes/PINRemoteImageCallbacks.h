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

@property (nonatomic, strong) PINRemoteImageManagerImageCompletion completionBlock;
@property (nonatomic, strong) PINRemoteImageManagerImageCompletion progressImageBlock;
@property (nonatomic, strong) PINRemoteImageManagerDownloadProgress downloadProgressBlock;
@property (nonatomic, assign) CFTimeInterval requestTime;

@end
