//
//  PINRemoteImageProcessorTask.m
//  Pods
//
//  Created by Garrett Moon on 3/9/15.
//
//

#import "PINRemoteImageProcessorTask.h"

@implementation PINRemoteImageProcessorTask

@synthesize downloadTaskUUID = _downloadTaskUUID;

- (BOOL)cancelWithUUID:(NSUUID *)UUID resume:(PINResume **)resume
{
    BOOL noMoreCompletions = [super cancelWithUUID:UUID resume:resume];
    [self.lock lockWithBlock:^{
        if (noMoreCompletions && _downloadTaskUUID) {
            [self.manager cancelTaskWithUUID:_downloadTaskUUID];
            _downloadTaskUUID = nil;
        }
    }];
    return noMoreCompletions;
}

- (void)setDownloadTaskUUID:(NSUUID *)downloadTaskUUID
{
    [self.lock lockWithBlock:^{
        NSAssert(_downloadTaskUUID == nil, @"downloadTaskUUID should be nil");
        _downloadTaskUUID = downloadTaskUUID;
    }];
}

- (NSUUID *)downloadTaskUUID
{
    __block NSUUID *downloadTaskUUID;
    [self.lock lockWithBlock:^{
        downloadTaskUUID = _downloadTaskUUID;
    }];
    return downloadTaskUUID;
}

@end
