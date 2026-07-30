//
//  PINProgressiveImageTests.m
//  PINRemoteImage Tests
//
//  Tests for the memory-safety fix to PINProgressiveImage's data hand-off:
//    - `-data` must survive an allocation failure by returning nil instead of
//      letting NSInvalidArgumentException escape (Bugsnag 67fad806301606795e34c849).
//    - `-hasData` must answer without copying the buffer.
//    - `-takeData` must transfer ownership without allocating, and must be
//      guarded so a late append after hand-off cannot silently corrupt state.
//

#import <XCTest/XCTest.h>
#import <objc/runtime.h>

#import <PINRemoteImage/PINProgressiveImage.h>
#import "PINProgressiveImage+Private.h"

/// Dynamically subclasses `object`'s class so that `-copy`/`-copyWithZone:` throw,
/// mimicking Foundation's page allocator raising NSInvalidArgumentException instead
/// of returning nil for a large allocation it can't satisfy. Scoped to the single
/// instance via isa-swizzling so it can't affect any other NSMutableData in the process.
static void PINTestMakeCopyThrowOnInstance(NSObject *object)
{
    Class originalClass = object_getClass(object);
    NSString *name = [NSString stringWithFormat:@"PINTestThrowingCopy_%@_%p", NSStringFromClass(originalClass), object];
    Class throwingClass = objc_allocateClassPair(originalClass, name.UTF8String, 0);

    IMP throwingCopyWithZoneIMP = imp_implementationWithBlock(^id(id _self, NSZone *zone) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException
                                        reason:@"*** NSAllocateMemoryPages(N) failed"
                                      userInfo:nil];
    });
    IMP throwingCopyIMP = imp_implementationWithBlock(^id(id _self) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException
                                        reason:@"*** NSAllocateMemoryPages(N) failed"
                                      userInfo:nil];
    });
    class_addMethod(throwingClass, @selector(copyWithZone:), throwingCopyWithZoneIMP, "@@:^{_NSZone=}");
    class_addMethod(throwingClass, @selector(copy), throwingCopyIMP, "@@:");

    objc_registerClassPair(throwingClass);
    object_setClass(object, throwingClass);
}

@interface PINProgressiveImageTests : XCTestCase

@end

@implementation PINProgressiveImageTests

- (PINProgressiveImage *)freshProgressiveImage
{
    NSURLSessionDataTask *dataTask = [[NSURLSession sharedSession] dataTaskWithURL:[NSURL URLWithString:@"https://example.com/image.jpg"]];
    return [[PINProgressiveImage alloc] initWithDataTask:dataTask];
}

#pragma mark - hasData

- (void)testHasDataIsFalseBeforeAnyDataArrives
{
    PINProgressiveImage *progressiveImage = [self freshProgressiveImage];
    XCTAssertFalse(progressiveImage.hasData);
    XCTAssertNil(progressiveImage.data);
    XCTAssertEqual(progressiveImage.data.length, (NSUInteger)0);
}

- (void)testHasDataIsTrueAfterDataArrives
{
    PINProgressiveImage *progressiveImage = [self freshProgressiveImage];
    NSData *chunk = [@"hello" dataUsingEncoding:NSUTF8StringEncoding];
    [progressiveImage updateProgressiveImageWithData:chunk expectedNumberOfBytes:(int64_t)chunk.length isResume:NO];

    XCTAssertTrue(progressiveImage.hasData);
    XCTAssertEqualObjects(progressiveImage.data, chunk);
    XCTAssertEqual(progressiveImage.data.length, chunk.length);
}

// Regression guard: an allocated-but-empty buffer must NOT be treated as "no data".
// This is the one case where `data.length == 0` and `hasData == NO` disagree; the
// retry/emptiness check in PINRemoteImageDownloadTask must use -hasData, not
// data.length, or a zero-byte `didReceiveData:` would newly become ErrorImageEmpty.
- (void)testHasDataIsTrueForAllocatedZeroLengthBuffer
{
    PINProgressiveImage *progressiveImage = [self freshProgressiveImage];
    [progressiveImage updateProgressiveImageWithData:[NSData data] expectedNumberOfBytes:0 isResume:NO];

    XCTAssertTrue(progressiveImage.hasData, @"An allocated (even if zero-length) buffer must count as having data, matching today's [mutableData copy] != nil behavior.");
    XCTAssertEqual(progressiveImage.data.length, (NSUInteger)0);
    XCTAssertNotNil(progressiveImage.data);
}

#pragma mark - takeData

- (void)testTakeDataReturnsFullBufferOnceThenNil
{
    PINProgressiveImage *progressiveImage = [self freshProgressiveImage];
    NSData *chunk = [@"the quick brown fox" dataUsingEncoding:NSUTF8StringEncoding];
    [progressiveImage updateProgressiveImageWithData:chunk expectedNumberOfBytes:(int64_t)chunk.length isResume:NO];

    NSData *taken = [progressiveImage takeData];
    XCTAssertEqualObjects(taken, chunk);

    XCTAssertNil([progressiveImage takeData], @"A second -takeData call must return nil, not the same buffer again.");
    XCTAssertFalse(progressiveImage.hasData, @"After -takeData, the object is terminal: hasData must be NO.");
    XCTAssertNil(progressiveImage.data, @"After -takeData, -data must be NO, not re-copy the (now nil'd) buffer.");
}

- (void)testTakeDataOnEmptyProgressiveImageReturnsNil
{
    PINProgressiveImage *progressiveImage = [self freshProgressiveImage];
    XCTAssertNil([progressiveImage takeData]);
}

// The mandatory companion to -takeData: mutableData == nil is an overloaded sentinel
// that means both "nothing received yet" and (post-fix) "already handed off". Without
// the dataTaken guard, a late append after -takeData would allocate a fresh, short
// buffer and silently feed it to CGImageSourceUpdateData, corrupting the decode instead
// of crashing. This test proves the guard makes updateProgressiveImageWithData: a no-op
// once data has been taken.
- (void)testLateAppendAfterTakeDataIsIgnored
{
    PINProgressiveImage *progressiveImage = [self freshProgressiveImage];
    NSData *firstChunk = [@"first" dataUsingEncoding:NSUTF8StringEncoding];
    [progressiveImage updateProgressiveImageWithData:firstChunk expectedNumberOfBytes:(int64_t)firstChunk.length isResume:NO];

    NSData *taken = [progressiveImage takeData];
    XCTAssertEqualObjects(taken, firstChunk);

    // Simulate a late in-flight `didReceiveData:` racing the completion handler.
    NSData *lateChunk = [@"late-arriving-bytes" dataUsingEncoding:NSUTF8StringEncoding];
    XCTAssertNoThrow([progressiveImage updateProgressiveImageWithData:lateChunk expectedNumberOfBytes:(int64_t)lateChunk.length isResume:NO]);

    XCTAssertFalse(progressiveImage.hasData, @"A late append after -takeData must be dropped, not silently start a new, short buffer.");
    XCTAssertEqual(progressiveImage.data.length, (NSUInteger)0);
    XCTAssertNil(progressiveImage.data);
}

#pragma mark - -data survives allocation failure

- (void)testDataReturnsNilInsteadOfThrowingWhenCopyFails
{
    PINProgressiveImage *progressiveImage = [self freshProgressiveImage];
    NSData *chunk = [@"payload" dataUsingEncoding:NSUTF8StringEncoding];
    [progressiveImage updateProgressiveImageWithData:chunk expectedNumberOfBytes:(int64_t)chunk.length isResume:NO];

    NSMutableData *mutableData = [progressiveImage valueForKey:@"mutableData"];
    XCTAssertNotNil(mutableData);
    PINTestMakeCopyThrowOnInstance(mutableData);

    __block NSData *data;
    XCTAssertNoThrow(data = progressiveImage.data, @"An allocation failure inside -copy must not escape -data as an exception.");
    XCTAssertNil(data);

    // The lock must not be left held: a subsequent call through the same lock must
    // not deadlock. (Regression coverage for the mutex-leak fix lives in
    // PINRemoteLockTests; this just confirms -data's own explicit lock/unlock pairs
    // correctly around the @try/@catch.)
    XCTAssertTrue(progressiveImage.hasData, @"hasData does not copy, so it must still reflect the buffer's presence even though -data failed.");
}

@end
