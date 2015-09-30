//
//  PINRemoteImageTask.h
//  Pods
//
//  Created by Garrett Moon on 3/9/15.
//
//

#import <Foundation/Foundation.h>

#import "PINRemoteImageManager.h"
#import "PINRemoteImage.h"

@interface PINRemoteImageTask : NSObject

@property (nonatomic, strong) NSMutableDictionary *callbackBlocks;
#if PINRemoteImageLogging
@property (nonatomic, copy) NSString *key;
#endif

- (void)addCallbacksWithCompletionBlock:(PINRemoteImageManagerImageCompletion)completionBlock progressBlock:(PINRemoteImageManagerImageCompletion)progressBlock withUUID:(NSUUID *)UUID;
- (void)removeCallbackWithUUID:(NSUUID *)UUID;
- (void)callCompletionsWithQueue:(dispatch_queue_t)queue remove:(BOOL)remove withImage:(UIImage *)image animatedImage:(FLAnimatedImage *)animatedImage cached:(BOOL)cached error:(NSError *)error;
//returns YES if no more attached completionBlocks
- (BOOL)cancelWithUUID:(NSUUID *)UUID manager:(PINRemoteImageManager *)manager;
- (void)setPriority:(PINRemoteImageManagerPriority)priority;

@end
