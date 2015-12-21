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

@property (nonatomic, strong, nullable) PINDataTaskOperation *urlSessionTaskOperation;
@property (nonatomic, assign) CFTimeInterval sessionTaskStartTime;
@property (nonatomic, assign) CFTimeInterval sessionTaskEndTime;
@property (nonatomic, assign) BOOL hasProgressBlocks;
@property (nonatomic, strong, nullable) PINProgressiveImage *progressImage;

- (void)callProgressWithQueue:(nonnull dispatch_queue_t)queue withImage:(nonnull UIImage *)image;

@end
