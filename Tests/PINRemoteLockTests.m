//
//  PINRemoteLockTests.m
//  PINRemoteImage Tests
//
//  Regression coverage for the mutex leak fixed in PINRemoteLock: before the fix,
//  an exception escaping the block passed to -lockWithBlock: skipped the matching
//  unlock, leaving the lock permanently held. That single bug meant every one of
//  PINProgressiveImage/PINRemoteImageDownloadTask's ~40 `lockWithBlock:` call sites
//  was one exception away from a permanent deadlock, not just the OOM copy site.
//

#import <XCTest/XCTest.h>
#import "PINRemoteLock.h"

@interface PINRemoteLockTests : XCTestCase

@end

@implementation PINRemoteLockTests

- (void)testLockWithBlockReleasesTheLockWhenTheBlockThrows
{
    PINRemoteLock *lock = [[PINRemoteLock alloc] initWithName:@"PINRemoteLockTests"];

    XCTAssertThrowsSpecificNamed({
        [lock lockWithBlock:^{
            @throw [NSException exceptionWithName:@"PINRemoteLockTestException" reason:@"boom" userInfo:nil];
        }];
    }, NSException, @"PINRemoteLockTestException");

    // If -lockWithBlock: leaked the lock on the exception above, this second
    // acquisition (deliberately from another thread, since the lock is
    // non-recursive) would hang forever instead of completing.
    XCTestExpectation *reacquired = [self expectationWithDescription:@"lock reacquired after throwing block"];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [lock lockWithBlock:^{
            [reacquired fulfill];
        }];
    });

    [self waitForExpectationsWithTimeout:5.0 handler:^(NSError * _Nullable error) {
        XCTAssertNil(error, @"lockWithBlock: appears to have leaked the mutex after an exception escaped the block.");
    }];
}

- (void)testLockWithBlockStillRunsAndUnlocksOnTheHappyPath
{
    PINRemoteLock *lock = [[PINRemoteLock alloc] initWithName:@"PINRemoteLockTests"];

    __block BOOL ran = NO;
    [lock lockWithBlock:^{
        ran = YES;
    }];
    XCTAssertTrue(ran);

    XCTestExpectation *reacquired = [self expectationWithDescription:@"lock reacquired on happy path"];
    [lock lockWithBlock:^{
        [reacquired fulfill];
    }];
    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

@end
