//
//  PINOperationQueue.h
//  Pods
//
//  Created by Garrett Moon on 8/23/16.
//
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, PINOperationQueuePriority) {
  PINOperationQueuePriorityLow,
  PINOperationQueuePriorityDefault,
  PINOperationQueuePriorityHigh,
};

@protocol PINOperationReference;

@interface PINOperationQueue : NSObject

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithMaxConcurrentOperations:(NSUInteger)maxConcurrentOperations;
- (instancetype)initWithMaxConcurrentOperations:(NSUInteger)maxConcurrentOperations concurrentQueue:(dispatch_queue_t)concurrentQueue NS_DESIGNATED_INITIALIZER;
+ (instancetype)sharedOperationQueue;

- (id <PINOperationReference>)addOperation:(dispatch_block_t)operation;
- (id <PINOperationReference>)addOperation:(dispatch_block_t)operation withPriority:(PINOperationQueuePriority)priority;

/**
 * Marks the operation as cancelled
 */
- (BOOL)cancelOperation:(id <PINOperationReference>)operationReference;

/**
 * Cancels all queued operations
 */
- (void)cancelAllOperations;

/*
 * Blocks the current thread until all of the receiver’s queued and executing operations finish executing.
 *
 * @discussion When called, this method blocks the current thread and waits for the receiver’s current and queued
 * operations to finish executing. While the current thread is blocked, the receiver continues to launch already
 * queued operations and monitor those that are executing.
 *
 * @warning This should never be called from within an operation submitted to the PINOperationQueue as this will result
 * in a deadlock.
 */
- (void)waitUntilAllOperationsAreFinished;

- (void)setOperationPriority:(PINOperationQueuePriority)priority withReference:(id <PINOperationReference>)reference;

@end

@protocol PINOperationReference <NSObject>

@end

NS_ASSUME_NONNULL_END
