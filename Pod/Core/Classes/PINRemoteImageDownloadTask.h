//
//  PINRemoteImageDownloadTask.h
//  Pods
//
//  Created by Garrett Moon on 3/9/15.
//
//

#import "PINRemoteImageTask.h"
#import "PINProgressiveImage.h"
#import "PINDataTaskOperation.h"

@interface PINRemoteImageDownloadTask : PINRemoteImageTask

@property (nonatomic, strong) PINDataTaskOperation *urlSessionTaskOperation;
@property (nonatomic, assign) CFTimeInterval sessionTaskStartTime;
@property (nonatomic, assign) CFTimeInterval sessionTaskEndTime;
@property (nonatomic, assign) BOOL hasProgressBlocks;
@property (nonatomic, strong) PINProgressiveImage *progressImage;

- (void)callProgressWithQueue:(dispatch_queue_t)queue withImage:(UIImage *)image;

@end
