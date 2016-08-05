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
-(nullable id)objectFromMemoryCacheForKey:(NSString *)key
{
    return [self.cache objectForKey:key];
}

-(void)cacheObjectInMemory:(id)object forKey:(NSString *)key withCost:(NSUInteger)cost
{
    [self.cache setObject:object forKey:key cost:cost];
}

//******************************************************************************************************
// Disk cache methods
//******************************************************************************************************
-(nullable id)objectFromDiskCacheForKey:(NSString *)key
{
    return [self.cache objectForKey:key];
}

-(void)objectFromDiskCacheForKey:(NSString *)key completion:(PINRemoteImageCachingObjectBlock)completion
{
    __weak typeof(self) welf = self;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if (completion) {
            __strong typeof(self) sself = welf;
            completion(sself, key, [sself.cache objectForKey:key]);
        }
    });
}

-(void)cacheObjectOnDisk:(id)object forKey:(NSString *)key
{
    [self.cache setObject:object forKey:key];
}

- (BOOL)objectExistsInCacheForKey:(NSString *)key
{
    return [self.cache objectForKey:key] != nil;
}

//******************************************************************************************************
// Common methods, should apply to both in-memory and disk storage
//******************************************************************************************************
- (void)removeCachedObjectForKey:(NSString *)key
{
    [self.cache removeObjectForKey:key];
}
- (void)removeCachedObjectForKey:(NSString *)key completion:(PINRemoteImageCachingObjectBlock)completion
{
    __weak typeof(self) welf = self;
    id object = [self.cache objectForKey:key];
    [self.cache removeObjectForKey:key];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if (completion) {
            __strong typeof(self) sself = welf;
            completion(sself, key, object);
        }
    });
}

- (void)removeAllCachedObjects
{
    [self.cache removeAllObjects];
}

@end
