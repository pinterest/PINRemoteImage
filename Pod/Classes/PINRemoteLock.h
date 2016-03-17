//
//  PINRemoteLock.h
//  Pods
//
//  Created by Garrett Moon on 3/17/16.
//
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, PINRemoteLockType) {
    PINRemoteLockTypeNonRecursive = 0,
    PINRemoteLockTypeRecursive,
};

@interface PINRemoteLock : NSObject

- (instancetype)initWithName:(NSString *)lockName lockType:(PINRemoteLockType)lockType NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithName:(NSString *)lockName;
- (void)lockWithBlock:(dispatch_block_t)block;

- (void)lock;
- (void)unlock;

@end
