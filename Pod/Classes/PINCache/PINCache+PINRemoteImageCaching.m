//
//  PINCache+PINRemoteImageCaching.m
//  Pods
//
//  Created by Aleksei Shevchenko on 7/28/16.
//
//

#import "PINCache+PINRemoteImageCaching.h"

@implementation PINCache (PINRemoteImageCaching)

//******************************************************************************************************
// Memory cache methods
//******************************************************************************************************
-(nullable id)objectFromMemoryCacheForKey:(NSString *)key
{
    return [self.memoryCache objectForKey:key];
}

-(void)cacheObjectInMemory:(id)object forKey:(NSString *)key withCost:(NSUInteger)cost
{
    [self.memoryCache setObject:object forKey:key withCost:cost];
}

//******************************************************************************************************
// Disk cache methods
//******************************************************************************************************
-(nullable id)objectFromDiskCacheForKey:(NSString *)key
{
    return [self.diskCache objectForKey:key];
}

-(void)objectFromDiskCacheForKey:(NSString *)key completion:(PINRemoteImageCachingObjectBlock)completion
{
    __weak typeof(self) welf = self;
    [self.diskCache objectForKey:key block:^(PINDiskCache * _Nonnull cache, NSString * _Nonnull key, id<NSCoding>  _Nullable object) {
        if(completion) {
            id sself = welf;
            completion(sself, key, object);
        }
    }];
}

-(void)cacheObjectOnDisk:(id)object forKey:(NSString *)key
{
    [self.diskCache setObject:object forKey:key];
}

- (BOOL)objectExistsInCacheForKey:(NSString *)key
{
    return [self containsObjectForKey:key];
}

//******************************************************************************************************
// Common cache methods
//******************************************************************************************************
- (void)removeCachedObjectForKey:(NSString *)key
{
    [self removeObjectForKey:key];
}
- (void)removeCachedObjectForKey:(NSString *)key completion:(PINRemoteImageCachingObjectBlock)completion
{
    __weak typeof(self) welf = self;
    [self removeObjectForKey:key block:^(PINCache * _Nonnull cache, NSString * _Nonnull key, id  _Nullable object) {
        if(completion) {
            id sself = welf;
            completion(sself, key, object);
        }
    }];
}

- (void)removeAllCachedObjects
{
    [self removeAllObjects];
}


@end
