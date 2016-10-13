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
-(nullable id)objectFromMemoryForKey:(NSString *)key
{
    return [self.memoryCache objectForKey:key];
}

-(void)setObjectInMemory:(id)object forKey:(NSString *)key withCost:(NSUInteger)cost
{
    [self.memoryCache setObject:object forKey:key withCost:cost];
}

- (void)removeObjectForKeyFromMemory:(NSString *)key
{
    [self.memoryCache removeObjectForKey:key];
}

//******************************************************************************************************
// Disk cache methods
//******************************************************************************************************
-(nullable id)objectFromDiskForKey:(NSString *)key
{
    return [self.diskCache objectForKey:key];
}

-(void)objectFromDiskForKey:(NSString *)key completion:(PINRemoteImageCachingObjectBlock)completion
{
    __weak typeof(self) weakSelf = self;
    [self.diskCache objectForKey:key block:^(PINDiskCache * _Nonnull cache, NSString * _Nonnull key, id<NSCoding>  _Nullable object) {
        if(completion) {
            typeof(self) strongSelf = weakSelf;
            completion(strongSelf, key, object);
        }
    }];
}

-(void)setObjectOnDisk:(id)object forKey:(NSString *)key
{
    [self.diskCache setObject:object forKey:key];
}

- (BOOL)objectExistsForKey:(NSString *)key
{
    return [self containsObjectForKey:key];
}

//******************************************************************************************************
// Common cache methods
//******************************************************************************************************
- (void)removeObjectForKey:(NSString *)key completion:(PINRemoteImageCachingObjectBlock)completion
{
  if (completion) {
    __weak typeof(self) weakSelf = self;
    [self removeObjectForKey:key block:^(PINCache * _Nonnull cache, NSString * _Nonnull key, id  _Nullable object) {
        typeof(self) strongSelf = weakSelf;
        completion(strongSelf, key, object);
    }];
  } else {
    [self removeObjectForKey:key block:nil];
  }
}

@end
