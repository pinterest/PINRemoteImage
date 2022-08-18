//
//  PINRemoteImageProcessorTask.h
//  Pods
//
//  Created by Garrett Moon on 3/9/15.
//
//

#import "Source/Classes/PINRemoteImageTask.h"

@interface PINRemoteImageProcessorTask : PINRemoteImageTask

@property (nonatomic, strong, nullable) NSUUID *downloadTaskUUID;

@end
