//
//  PINRemoteImageCaching.h
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
- (nullable id)objectFromMemoryForKey:(NSString *)key;
- (void)setObjectInMemory:(id)object forKey:(NSString *)key withCost:(NSUInteger)cost;

//******************************************************************************************************
// Disk cache methods
//******************************************************************************************************
- (nullable id)objectFromDiskForKey:(NSString *)key;
- (void)objectFromDiskForKey:(NSString *)key completion:(nullable PINRemoteImageCachingObjectBlock)completion;
- (void)setObjectOnDisk:(id)object forKey:(NSString *)key;


- (BOOL)objectExistsForKey:(NSString *)key;

- (void)removeObjectForKey:(NSString *)key;
- (void)removeObjectForKey:(NSString *)key completion:(nullable PINRemoteImageCachingObjectBlock)completion;
- (void)removeAllObjects;

@optional

- (void)removeObjectForKeyFromMemory:(NSString *)key;
- (void)setObjectInMemory:(id)object forKey:(NSString *)key withCost:(NSUInteger)cost withAgeLimit:(NSTimeInterval)ageLimit;
- (void)setObjectOnDisk:(id)object forKey:(NSString *)key withAgeLimit:(NSTimeInterval)ageLimit;
- (BOOL)memoryCacheIsTTLCache;
- (BOOL)diskCacheIsTTLCache;

@end


NS_ASSUME_NONNULL_END
