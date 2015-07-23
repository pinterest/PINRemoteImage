//
//  PINRemoteImageTask.m
//  Pods
//
//  Created by Garrett Moon on 3/9/15.
//
//

#import "PINRemoteImageTask.h"

#import "PINRemoteImage.h"
#import "PINRemoteImageCallbacks.h"

@implementation PINRemoteImageTask

- (instancetype)init
{
    if (self = [super init]) {
        self.callbackBlocks = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p> completionBlocks: %lu", NSStringFromClass([self class]), self, (unsigned long)self.callbackBlocks.count];
}

- (void)addCallbacksWithCompletionBlock:(PINRemoteImageManagerImageCompletion)completionBlock progressBlock:(PINRemoteImageManagerImageCompletion)progressBlock withUUID:(NSUUID *)UUID
{
    PINRemoteImageCallbacks *completion = [[PINRemoteImageCallbacks alloc] init];
    completion.completionBlock = completionBlock;
    completion.progressBlock = progressBlock;
    
    [self.callbackBlocks setObject:completion forKey:UUID];
}

- (void)removeCallbackWithUUID:(NSUUID *)UUID
{
    [self.callbackBlocks removeObjectForKey:UUID];
}

- (void)callCompletionsWithQueue:(dispatch_queue_t)queue
                          remove:(BOOL)remove
                       withImage:(UIImage *)image
                   animatedImage:(FLAnimatedImage *)animatedImage
                          cached:(BOOL)cached
                           error:(NSError *)error
{
    __weak typeof(self) weakSelf = self;
    [self.callbackBlocks enumerateKeysAndObjectsUsingBlock:^(NSUUID *UUID, PINRemoteImageCallbacks *callback, BOOL *stop) {
        typeof(self) strongSelf = weakSelf;
        if (callback.completionBlock != nil) {
            PINLog(@"calling completion for UUID: %@ key: %@", UUID, strongSelf.key);
            dispatch_async(queue, ^
            {
                callback.completionBlock([PINRemoteImageManagerResult imageResultWithImage:image
                                                                            animatedImage:animatedImage
                                                                            requestLength:CACurrentMediaTime() - callback.requestTime
                                                                                    error:error
                                                                               resultType:cached?PINRemoteImageResultTypeCache:PINRemoteImageResultTypeDownload
                                                                                     UUID:UUID]);
            });
        }
        if (remove) {
            [strongSelf removeCallbackWithUUID:UUID];
        }
    }];
}

- (BOOL)cancelWithUUID:(NSUUID *)UUID manager:(PINRemoteImageManager *)manager
{
    BOOL noMoreCompletions = NO;
    [self removeCallbackWithUUID:UUID];
    if ([self.callbackBlocks count] == 0) {
        noMoreCompletions = YES;
    }
    return noMoreCompletions;
}

- (void)setPriority:(PINRemoteImageManagerPriority)priority
{
    
}

@end
