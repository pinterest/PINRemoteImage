#import "PINDiskCache+PINCacheTests.h"

@interface PINDiskCache () {
    BOOL _ttlCache;
}

- (void)lock;
- (void)lockAndWaitForKnownState;
- (void)unlock;

@end

@implementation PINDiskCache (PINCacheTests)

- (void)setTtlCacheSync:(BOOL)ttlCache
{
    [self lock];
        self->_ttlCache = ttlCache;
    [self unlock];
}

- (void)waitForKnownState
{
    [self lockAndWaitForKnownState];
    [self unlock];
}

@end
