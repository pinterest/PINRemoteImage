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
-(nullable id)objectCachedInMemoryForKey:(NSString *)key
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
-(nullable id)objectCachedOnDiskForKey:(NSString *)key
{
    return [self.cache objectForKey:key];
}

-(void)objectCachedOnDiskForKey:(NSString *)key block:(PINRemoteImageCachingObjectBlock)block
{
    __weak typeof(self) welf = self;
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), ^{
        if(block) {
            __strong typeof(self) sself = welf;
            block(sself, key, [sself.cache objectForKey:key]);
        }
    });
}

-(void)cacheObjectOnDisk:(id)object forKey:(NSString *)key
{
    [self.cache setObject:object forKey:key];
}

- (BOOL)hasObjectForKey:(NSString *)key
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
- (void)removeCachedObjectForKey:(NSString *)key block:(PINRemoteImageCachingObjectBlock)block
{
    __weak typeof(self) welf = self;
    id object = [self.cache objectForKey:key];
    [self.cache removeObjectForKey:key];
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), ^{
        if(block) {
            __strong typeof(self) sself = welf;
            block(sself, key, object);
        }
    });
}

- (void)removeAllCachedObjects
{
    [self.cache removeAllObjects];
}

@end
