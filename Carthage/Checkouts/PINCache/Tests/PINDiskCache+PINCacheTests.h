#import "PINCache.h"

@interface PINDiskCache (PINCacheTests)

/**
 Sets `ttlCache` property synchronously. This is normally set asyncronously, but for testing purposes it is useful block until the
 actual value has been set.
 */
- (void)setTtlCacheSync:(BOOL)ttlCache;

/**
 Waits until all metadata has been read off the disk
 */
- (void)waitForKnownState;

@end
