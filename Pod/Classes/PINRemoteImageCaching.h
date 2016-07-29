//
//  PINImageCacheProtocol.h
//  Pods
//
//  Created by Aleksei Shevchenko on 7/25/16.
//
//

#import <Foundation/Foundation.h>


NS_ASSUME_NONNULL_BEGIN

@protocol PINRemoteImageCaching;
typedef void (^PINRemoteImageCachingObjectBlock)(id<PINRemoteImageCaching> cache, NSString *key, id __nullable object);

/**
 *  Image Cache is responsible for actual image caching.
 */
@protocol PINRemoteImageCaching <NSObject>

//******************************************************************************************************
// Memory cache methods
//******************************************************************************************************
- (nullable id)objectCachedInMemoryForKey:(NSString *)key;
- (void)cacheObjectInMemory:(id)object forKey:(NSString *)key withCost:(NSUInteger)cost;

//******************************************************************************************************
// Disk cache methods
//******************************************************************************************************
- (nullable id)objectCachedOnDiskForKey:(NSString *)key;
- (void)objectCachedOnDiskForKey:(NSString *)key block:(PINRemoteImageCachingObjectBlock)block;
- (void)cacheObjectOnDisk:(id)object forKey:(NSString *)key;


- (BOOL)hasObjectForKey:(NSString *)key;

- (void)removeCachedObjectForKey:(NSString *)key;
- (void)removeCachedObjectForKey:(NSString *)key block:(PINRemoteImageCachingObjectBlock)block;
- (void)removeAllCachedObjects;

@end


NS_ASSUME_NONNULL_END
