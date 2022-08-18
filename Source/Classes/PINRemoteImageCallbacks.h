//
//  PINRemoteImageCallbacks.h
//  Pods
//
//  Created by Garrett Moon on 3/9/15.
//
//

#import <Foundation/Foundation.h>

#import "Source/Classes/include/PINRemoteImageManager.h"

@interface PINRemoteImageCallbacks : NSObject

@property (atomic, strong, nullable) PINRemoteImageManagerImageCompletion completionBlock;
@property (atomic, strong, nullable) PINRemoteImageManagerImageCompletion progressImageBlock;
@property (atomic, strong, nullable) PINRemoteImageManagerProgressDownload progressDownloadBlock;
@property (assign, readonly) CFTimeInterval requestTime;

@end
