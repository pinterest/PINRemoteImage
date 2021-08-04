//
//  PINRemoteImageBasicCache.m
//  Pods
//
//  Created by Aleksei Shevchenko on 7/28/16.
//
//

#import "PINRemoteImageBasicCache.h"

@interface PINRemoteImageBasicCache()
@property (nonatomic, strong) NSCache *cache;
@end

@implementation PINRemoteImageBasicCache

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.cache = [[NSCache alloc] init];
    }
    return self;
}

//******************************************************************************************************
// Memory cache methods
//******************************************************************************************************
-(nullable id)objectFromMemoryForKey:(NSString *)key
{
    return [self.cache objectForKey:key];
}

-(void)setObjectInMemory:(id)object forKey:(NSString *)key withCost:(NSUInteger)cost
{
    [self.cache setObject:object forKey:key cost:cost];
}

- (void)removeObjectForKeyFromMemory:(NSString *)key
{
    [self.cache removeObjectForKey:key];
}

//******************************************************************************************************
// Disk cache methods
//******************************************************************************************************
-(nullable id)objectFromDiskForKey:(NSString *)key
{
    return nil;
}

-(void)objectFromDiskForKey:(NSString *)key completion:(PINRemoteImageCachingObjectBlock)completion
{
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if (completion) {
            typeof(self) strongSelf = weakSelf;
            completion(strongSelf, key, nil);
        }
    });
}

-(void)setObjectOnDisk:(id)object forKey:(NSString *)key
{
    
}

//******************************************************************************************************
// Common methods, should apply to both in-memory and disk storage
//******************************************************************************************************
- (BOOL)objectExistsForKey:(NSString *)key
{
    return [self.cache objectForKey:key] != nil;
}

- (void)removeObjectForKey:(NSString *)key
{
    [self.cache removeObjectForKey:key];
}

- (void)removeObjectForKey:(NSString *)key completion:(PINRemoteImageCachingObjectBlock)completion
{
    __weak typeof(self) weakSelf = self;
    id object = [self.cache objectForKey:key];
    [self.cache removeObjectForKey:key];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if (completion) {
            typeof(self) strongSelf = weakSelf;
            completion(strongSelf, key, object);
        }
    });
}

- (void)removeAllObjects
{
    [self.cache removeAllObjects];
}

@end
