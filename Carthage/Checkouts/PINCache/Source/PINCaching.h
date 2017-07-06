//
//  PINCaching.h
//  PINCache
//
//  Created by Michael Schneider on 1/31/17.
//  Copyright © 2017 Pinterest. All rights reserved.
//

#pragma once
#import <Foundation/Foundation.h>


NS_ASSUME_NONNULL_BEGIN

@protocol PINCaching;

/**
 A callback block which provides only the cache as an argument
 */
typedef void (^PINCacheBlock)(id<PINCaching> cache);

/**
 A callback block which provides the cache, key and object as arguments
 */
typedef void (^PINCacheObjectBlock)(id<PINCaching> cache, NSString *key, id _Nullable object);

/**
 A callback block which provides a BOOL value as argument
 */
typedef void (^PINCacheObjectContainmentBlock)(BOOL containsObject);

@protocol PINCaching <NSObject>

#pragma mark - Core

/**
 The name of this cache, used to create a directory under Library/Caches and also appearing in stack traces.
 */
@property (readonly) NSString *name;

#pragma mark - Asynchronous Methods

/// @name Asynchronous Methods

/**
 This method determines whether an object is present for the given key in the cache. This method returns immediately
 and executes the passed block after the object is available, potentially in parallel with other blocks on the
 <concurrentQueue>.
 
 @see containsObjectForKey:
 @param key The key associated with the object.
 @param block A block to be executed concurrently after the containment check happened
 */
- (void)containsObjectForKeyAsync:(NSString *)key completion:(PINCacheObjectContainmentBlock)block;

/**
 Retrieves the object for the specified key. This method returns immediately and executes the passed
 block after the object is available, potentially in parallel with other blocks on the <concurrentQueue>.
 
 @param key The key associated with the requested object.
 @param block A block to be executed concurrently when the object is available.
 */
- (void)objectForKeyAsync:(NSString *)key completion:(PINCacheObjectBlock)block;

/**
 Stores an object in the cache for the specified key. This method returns immediately and executes the
 passed block after the object has been stored, potentially in parallel with other blocks on the <concurrentQueue>.
 
 @param object An object to store in the cache.
 @param key A key to associate with the object. This string will be copied.
 @param block A block to be executed concurrently after the object has been stored, or nil.
 */
- (void)setObjectAsync:(id)object forKey:(NSString *)key completion:(nullable PINCacheObjectBlock)block;

/**
 Stores an object in the cache for the specified key and the specified memory cost. If the cost causes the total
 to go over the <memoryCache.costLimit> the cache is trimmed (oldest objects first). This method returns immediately
 and executes the passed block after the object has been stored, potentially in parallel with other blocks
 on the <concurrentQueue>.
 
 @param object An object to store in the cache.
 @param key A key to associate with the object. This string will be copied.
 @param cost An amount to add to the <memoryCache.totalCost>.
 @param block A block to be executed concurrently after the object has been stored, or nil.
 */
- (void)setObjectAsync:(id)object forKey:(NSString *)key withCost:(NSUInteger)cost completion:(nullable PINCacheObjectBlock)block;

/**
 Removes the object for the specified key. This method returns immediately and executes the passed
 block after the object has been removed, potentially in parallel with other blocks on the <concurrentQueue>.
 
 @param key The key associated with the object to be removed.
 @param block A block to be executed concurrently after the object has been removed, or nil.
 */
- (void)removeObjectForKeyAsync:(NSString *)key completion:(nullable PINCacheObjectBlock)block;

/**
 Removes all objects from the cache that have not been used since the specified date. This method returns immediately and
 executes the passed block after the cache has been trimmed, potentially in parallel with other blocks on the <concurrentQueue>.
 
 @param date Objects that haven't been accessed since this date are removed from the cache.
 @param block A block to be executed concurrently after the cache has been trimmed, or nil.
 */
- (void)trimToDateAsync:(NSDate *)date completion:(nullable PINCacheBlock)block;

/**
 Removes all objects from the cache.This method returns immediately and executes the passed block after the
 cache has been cleared, potentially in parallel with other blocks on the <concurrentQueue>.
 
 @param block A block to be executed concurrently after the cache has been cleared, or nil.
 */
- (void)removeAllObjectsAsync:(nullable PINCacheBlock)block;


#pragma mark - Synchronous Methods
/// @name Synchronous Methods

/**
 This method determines whether an object is present for the given key in the cache.
 
 @see containsObjectForKeyAsync:completion:
 @param key The key associated with the object.
 @result YES if an object is present for the given key in the cache, otherwise NO.
 */
- (BOOL)containsObjectForKey:(NSString *)key;

/**
 Retrieves the object for the specified key. This method blocks the calling thread until the object is available.
 Uses a lock to achieve synchronicity on the disk cache.
 
 @see objectForKeyAsync:completion:
 @param key The key associated with the object.
 @result The object for the specified key.
 */
- (nullable id)objectForKey:(NSString *)key;

/**
 Stores an object in the cache for the specified key. This method blocks the calling thread until the object has been set.
 Uses a lock to achieve synchronicity on the disk cache.
 
 @see setObjectAsync:forKey:completion:
 @param object An object to store in the cache.
 @param key A key to associate with the object. This string will be copied.
 */
- (void)setObject:(nullable id)object forKey:(NSString *)key;

/**
 Stores an object in the cache for the specified key and the specified memory cost. If the cost causes the total
 to go over the <memoryCache.costLimit> the cache is trimmed (oldest objects first). This method blocks the calling thread
 until the object has been stored.
 
 @param object An object to store in the cache.
 @param key A key to associate with the object. This string will be copied.
 @param cost An amount to add to the <memoryCache.totalCost>.
 */
- (void)setObject:(nullable id)object forKey:(NSString *)key withCost:(NSUInteger)cost;

/**
 Removes the object for the specified key. This method blocks the calling thread until the object
 has been removed.
 Uses a lock to achieve synchronicity on the disk cache.
 
 @see removeObjectForKeyAsync:completion:
 @param key The key associated with the object to be removed.
 */
- (void)removeObjectForKey:(NSString *)key;

/**
 Removes all objects from the cache that have not been used since the specified date.
 This method blocks the calling thread until the cache has been trimmed.
 Uses a lock to achieve synchronicity on the disk cache.
 
 @see trimToDateAsync:completion:
 @param date Objects that haven't been accessed since this date are removed from the cache.
 */
- (void)trimToDate:(NSDate *)date;

/**
 Removes all objects from the cache. This method blocks the calling thread until the cache has been cleared.
 Uses a lock to achieve synchronicity on the disk cache.
 
 @see removeAllObjectsAsync:
 */
- (void)removeAllObjects;

@end

NS_ASSUME_NONNULL_END

