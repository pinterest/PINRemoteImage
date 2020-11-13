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
    [self setValue:@(ttlCache) forKey:@"_ttlCache"];
    [self unlock];
}

- (void)waitForKnownState
{
    [self lockAndWaitForKnownState];
    [self unlock];
}

@end
