//
//  PINOperationQueueTests.m
//  PINOperationQueue
//
//  Created by Garrett Moon on 8/28/16.
//  Copyright © 2016 Pinterest. All rights reserved.
//

@import PINOperation;
#import <XCTest/XCTest.h>
#import <pthread.h>

static NSTimeInterval PINOperationQueueTestBlockTimeout = 20;

@interface PINOperationQueueTests : XCTestCase

@property (nonatomic, strong) PINOperationQueue *queue;

@end

static const NSUInteger PINOperationQueueTestsLowestMaxOperations = 1;
static const NSUInteger PINOperationQueueTestsMaxOperations = 5;

@implementation PINOperationQueueTests

- (void)setUp
{
  [super setUp];
  self.queue = [[PINOperationQueue alloc] initWithMaxConcurrentOperations:PINOperationQueueTestsMaxOperations];
  // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
  // Put teardown code here. This method is called after the invocation of each test method in the class.
  self.queue = nil;
  [super tearDown];
}

- (dispatch_time_t)timeout
{
  return dispatch_time(DISPATCH_TIME_NOW, (int64_t)(PINOperationQueueTestBlockTimeout * NSEC_PER_SEC));
}

- (void)testAllOperationsRun
{
  const NSUInteger operationCount = 100;
  dispatch_group_t group = dispatch_group_create();
  
  for (NSUInteger count = 0; count < operationCount; count++) {
    dispatch_group_enter(group);
    [self.queue scheduleOperation:^{
      dispatch_group_leave(group);
    } withPriority:PINOperationQueuePriorityDefault];
  }
  
  NSUInteger success = dispatch_group_wait(group, [self timeout]);
  XCTAssert(success == 0, @"Timed out before completing 100 operations");
}

- (void)testAllOperationsReleased
{
  const NSUInteger operationCount = 100;
  NSPointerArray *weakOperationPointers = [NSPointerArray weakObjectsPointerArray];
  
  for (int i = 0; i < operationCount; i++) {
    @autoreleasepool {
      dispatch_block_t operation = ^{
        usleep(i);
      };
      
      [weakOperationPointers addPointer:(__bridge void * _Nullable)(operation)];
      [self.queue scheduleOperation:operation withPriority:PINOperationQueuePriorityDefault];
    }
  }
  
  [self.queue waitUntilAllOperationsAreFinished];
  
  // Autorelease pool is drained at the end of each run loop
  // Dispatch to the next loop before asserting that all blocks are gone
  XCTestExpectation *expectation = [self expectationWithDescription:@"next run loop expectation"];
  dispatch_async(dispatch_get_main_queue(), ^{
    [expectation fulfill];
  });
  
  [self waitForExpectationsWithTimeout:10 handler:nil];
  XCTAssertEqual(0, weakOperationPointers.allObjects.count);
}

- (void)testWaitUntilAllOperationsFinished
{
  const NSUInteger operationCount = 100;
  __block NSInteger operationsRun = 0;

  __weak PINOperationQueueTests *weakSelf = self;
  for (NSUInteger count = 0; count < operationCount; count++) {
    [self.queue scheduleOperation:^{
      __strong PINOperationQueueTests *strongSelf = weakSelf;
      @synchronized (strongSelf) {
        operationsRun += 1;
      }
    } withPriority:PINOperationQueuePriorityDefault];
  }
  
  [self.queue waitUntilAllOperationsAreFinished];
  
  XCTAssert(operationCount == operationsRun, @"Timed out before completing 100 operations");
}

- (void)testWaitUntilAllOperationsFinishedWithNestedOperations
{
  const NSUInteger operationCount = 100;
    
  __block NSInteger operationsRun = 0;
  for (NSUInteger count = 0; count < operationCount; count++) {
    __weak PINOperationQueueTests *weakSelf = self;
    [self.queue scheduleOperation:^{
      __strong PINOperationQueueTests *strongSelf = weakSelf;
      @synchronized (strongSelf) {
        operationsRun += 1;
      }
      [strongSelf.queue scheduleOperation:^{
        __strong PINOperationQueueTests *strongSelf = weakSelf;
        @synchronized (strongSelf) {
          operationsRun += 1;
        }
      } withPriority:PINOperationQueuePriorityHigh];
    } withPriority:PINOperationQueuePriorityDefault];
  }

  [self.queue waitUntilAllOperationsAreFinished];

  XCTAssert(operationsRun == (operationCount*2), @"Timed out before completing 100 operations");
}

- (void)helperConfirmMaxOperations:(NSUInteger)maxOperations queue:(PINOperationQueue *)queue
{
  const NSUInteger operationCount = 100;
  dispatch_group_t group = dispatch_group_create();
  
  __block NSUInteger runningOperationCount = 0;
  __block BOOL operationCountMaxedOut = NO;
  
  XCTAssert(queue.maxConcurrentOperations == maxOperations, @"Max concurrent operations not correctly set.");
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-retain-cycles"
  for (NSUInteger count = 0; count < operationCount; count++) {
    dispatch_group_enter(group);
    [queue scheduleOperation:^{
      @synchronized (self) {
        runningOperationCount++;
        if (runningOperationCount == maxOperations) {
          operationCountMaxedOut = YES;
        }
        XCTAssert(runningOperationCount <= maxOperations, @"Running too many operations at once: %lu", (unsigned long)runningOperationCount);
      }
      
      usleep(10000);
      
      @synchronized (self) {
        runningOperationCount--;
        XCTAssert(runningOperationCount <= maxOperations, @"Running too many operations at once: %lu", (unsigned long)runningOperationCount);
      }
      
      dispatch_group_leave(group);
    } withPriority:PINOperationQueuePriorityDefault];
  }
#pragma clang diagnostic pop
  
  NSUInteger success = dispatch_group_wait(group, [self timeout]);
  XCTAssert(success == 0, @"Timed out before completing 100 operations");
  XCTAssert(operationCountMaxedOut == YES, @"Never reached maximum number of concurrent operations: %lu", (unsigned long)maxOperations);
}

- (void)testMaximumNumberOfConcurrentOperations
{
  [self helperConfirmMaxOperations:PINOperationQueueTestsMaxOperations queue:self.queue];
}

- (void)testMaximumNumberOfConcurrentOperationsIsOne
{
  self.queue = [[PINOperationQueue alloc] initWithMaxConcurrentOperations:PINOperationQueueTestsLowestMaxOperations];
  [self helperConfirmMaxOperations:PINOperationQueueTestsLowestMaxOperations queue:self.queue];
}

//We expect operations to run in priority order when added in that order as well
- (void)testPriority
{
  const NSUInteger highOperationCount = 100;
  const NSUInteger defaultOperationCount = 100;
  const NSUInteger lowOperationCount = 100;
  
  __block NSUInteger highOperationComplete = 0;
  __block NSUInteger defaultOperationComplete = 0;
  __block NSUInteger lowOperationComplete = 0;
  
  dispatch_group_t group = dispatch_group_create();
  
  //This is actually a pretty annoying unit test to write. Because multiple operations are allowed to be concurrent, lower priority operations can potentially repeatidly
  //obtain the lock while higher priority operations wait… So I'm attempting to make the operations less about lock contention and more about the length of time they take
  //to execute and adding a sleep before they obtain the lock to hopefully improve reliability.
  
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-retain-cycles"
  for (NSUInteger count = 0; count < highOperationCount; count++) {
    dispatch_group_enter(group);
    [self.queue scheduleOperation:^{
      usleep(10000);
      @synchronized (self) {
        ++highOperationComplete;
        XCTAssert(defaultOperationComplete <= PINOperationQueueTestsMaxOperations, @"Running default operations before high. Default operations complete: %lu", (unsigned long)defaultOperationComplete);
        XCTAssert(lowOperationComplete <= PINOperationQueueTestsMaxOperations, @"Running low operations before high. Low operations complete: %lu", (unsigned long)lowOperationComplete);
      }
      dispatch_group_leave(group);
    } withPriority:PINOperationQueuePriorityHigh];
  }
  
  for (NSUInteger count = 0; count < defaultOperationCount; count++) {
    dispatch_group_enter(group);
    [self.queue scheduleOperation:^{
      usleep(10000);
      @synchronized (self) {
        ++defaultOperationComplete;
        XCTAssert(lowOperationComplete <= PINOperationQueueTestsMaxOperations, @"Running low operations before default. Low operations complete: %lu", (unsigned long)lowOperationComplete);
        XCTAssert(highOperationComplete > highOperationCount - PINOperationQueueTestsMaxOperations, @"Running high operations after default. High operations complete: %lu", (unsigned long)highOperationComplete);
      }
      dispatch_group_leave(group);
    } withPriority:PINOperationQueuePriorityDefault];
  }
  
  for (NSUInteger count = 0; count < lowOperationCount; count++) {
    dispatch_group_enter(group);
    [self.queue scheduleOperation:^{
      usleep(10000);
      @synchronized (self) {
        ++lowOperationComplete;
        XCTAssert(defaultOperationComplete > defaultOperationCount - PINOperationQueueTestsMaxOperations, @"Running default operations after low. Default operations complete: %lu", (unsigned long)defaultOperationComplete);
        XCTAssert(highOperationComplete > highOperationCount - PINOperationQueueTestsMaxOperations, @"Running high operations after low. High operations complete: %lu", (unsigned long)highOperationComplete);
      }
      dispatch_group_leave(group);
    } withPriority:PINOperationQueuePriorityLow];
  }
#pragma clang diagnostic pop
  
  NSUInteger success = dispatch_group_wait(group, [self timeout]);
  XCTAssert(success == 0, @"Timed out");
}

//We expect low priority operations to eventually run even if the queue is continually kept full with higher priority operations
- (void)testOutOfOrderOperations
{
  const NSUInteger operationCount = 100;
  dispatch_group_t group = dispatch_group_create();
  
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-retain-cycles"
  for (NSUInteger count = 0; count < PINOperationQueueTestsMaxOperations + 1; count++) {
    [self.queue scheduleOperation:^{
      [self recursivelyAddOperation];
    } withPriority:PINOperationQueuePriorityHigh];
  }
#pragma clang diagnostic pop
  
  for (NSUInteger count = 0; count < operationCount; count++) {
    dispatch_group_enter(group);
    [self.queue scheduleOperation:^{
      dispatch_group_leave(group);
    } withPriority:PINOperationQueuePriorityLow];
  }
  
  NSUInteger success = dispatch_group_wait(group, [self timeout]);
  XCTAssert(success == 0, @"Timed out");
}

- (void)recursivelyAddOperation
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-retain-cycles"
  [self.queue scheduleOperation:^{
    [self recursivelyAddOperation];
  } withPriority:PINOperationQueuePriorityHigh];
#pragma clang diagnostic pop
}

- (void)testCancelation
{
  const NSUInteger sleepTime = 100000;
  for (NSUInteger count = 0; count < PINOperationQueueTestsMaxOperations + 1; count++) {
    [self.queue scheduleOperation:^{
      usleep(sleepTime);
    } withPriority:PINOperationQueuePriorityDefault];
  }
  
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-retain-cycles"
  id <PINOperationReference> operation = [self.queue scheduleOperation:^{
    XCTAssertTrue(NO, @"operation should have been canceled");
  } withPriority:PINOperationQueuePriorityDefault];
#pragma clang diagnostics pop
  
  [self.queue cancelOperation:operation];
  
  usleep(sleepTime * (PINOperationQueueTestsMaxOperations + 1));
}

- (void)testChangingPriority
{
  const NSUInteger defaultOperationCount = 100;
  
  __block NSUInteger defaultOperationComplete = 0;
  
  dispatch_group_t group = dispatch_group_create();
  
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-retain-cycles"
  for (NSUInteger count = 0; count < defaultOperationCount; count++) {
    dispatch_group_enter(group);
    [self.queue scheduleOperation:^{
      usleep(100);
      @synchronized (self) {
        ++defaultOperationComplete;
      }
      dispatch_group_leave(group);
    } withPriority:PINOperationQueuePriorityDefault];
  }
  
  dispatch_group_enter(group);
  id <PINOperationReference> operation = [self.queue scheduleOperation:^{
    @synchronized (self) {
      //Make sure we're less than defaultOperationCount - PINOperationQueueTestsMaxOperations because this operation could start even while the others are running even
      //if started last.
      XCTAssert(defaultOperationComplete < defaultOperationCount - PINOperationQueueTestsMaxOperations, @"operation was not completed before default operations even though reprioritized.");
    }
    dispatch_group_leave(group);
  } withPriority:PINOperationQueuePriorityLow];
#pragma clang diagnostic pop
  [self.queue setOperationPriority:PINOperationQueuePriorityHigh withReference:operation];
  
  NSUInteger success = dispatch_group_wait(group, [self timeout]);
  XCTAssert(success == 0, @"Timed out");
}

- (void)testCoalescingOperations
{
    self.queue = [[PINOperationQueue alloc] initWithMaxConcurrentOperations:PINOperationQueueTestsMaxOperations];
    
    const NSUInteger totalOperationCount = 100;
    dispatch_group_t group = dispatch_group_create();
    
    NSString *normalDesc = @"Normal";
    NSString *coallescedDesc = @"Coallesced";
    NSArray<NSString *> *descs = @[normalDesc, coallescedDesc];
    
    __block NSMutableDictionary<NSString *, NSNumber *> *operationCount = [NSMutableDictionary dictionaryWithObjectsAndKeys:@(0), normalDesc, @(0), coallescedDesc, nil];
    __block NSMutableDictionary<NSString *, NSNumber *> *operationRun = [NSMutableDictionary dictionaryWithObjectsAndKeys:@(0), normalDesc, @(0), coallescedDesc, nil];
    __block NSMutableDictionary<NSString *, NSNumber *> *operationComplete = [NSMutableDictionary dictionaryWithObjectsAndKeys:@(0), normalDesc, @(0), coallescedDesc, nil];

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-retain-cycles"
    // Fill up the queue with dummy operations so we have time to add real ones without them being unexpectedly executed
    for (NSUInteger i = 0; i < PINOperationQueueTestsMaxOperations * 2; i++) {
        dispatch_group_enter(group);
        [self.queue scheduleOperation:^{
            usleep(1000);
            dispatch_group_leave(group);
        }];
    }
    
    for (NSUInteger i = 0; i < totalOperationCount; i++) {
        dispatch_group_enter(group);

        NSString *desc = descs[i % descs.count];
        BOOL isNormalOperation = [desc isEqualToString:normalDesc];
        
        NSString *identifier = desc;
        if (isNormalOperation) {
            identifier = [NSString stringWithFormat:@"%@ %tu", desc, i];
        }
        
        operationCount[desc] = @([operationCount[desc] intValue] + 1);
        
        PINOperationBlock operation = ^(id  _Nullable data) {
            @synchronized (self) {
                operationRun[desc] = @([operationRun[desc] intValue] + 1);
            }
        };
        
        dispatch_block_t completion = ^{
            @synchronized (self) {
                operationComplete[desc] = @([operationComplete[desc] intValue] + 1);
            }
            dispatch_group_leave(group);
        };
        
        [self.queue scheduleOperation:operation
                    withPriority:PINOperationQueuePriorityLow
                      identifier:identifier
                  coalescingData:nil
             dataCoalescingBlock:nil
                      completion:completion];
    }
#pragma clang diagnostic pop
    
    NSUInteger success = dispatch_group_wait(group, [self timeout]);
    XCTAssert(success == 0, @"Timed out");
    XCTAssert([operationRun[normalDesc] intValue] == [operationCount[normalDesc] intValue]);
    XCTAssert([operationComplete[normalDesc] intValue] == [operationCount[normalDesc] intValue]);
    XCTAssert([operationRun[coallescedDesc] intValue] == 1);
    XCTAssert([operationComplete[coallescedDesc] intValue] == [operationCount[coallescedDesc] intValue]);
}

- (void)testCoalescingOperationCompletions
{
    dispatch_group_t group = dispatch_group_create();
    
    NSArray<NSNumber *> *completionFlags = @[@(NO), @(NO), @(YES), @(NO), @(YES)];
    NSIndexSet *expectedCompletedIndexSet = [completionFlags indexesOfObjectsPassingTest:^BOOL(NSNumber * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) { return [obj boolValue]; }];
    NSMutableIndexSet *completedIndexSet = [NSMutableIndexSet indexSet];
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-retain-cycles"
    // Fill up the queue with dummy operations so we have time to add real ones without them being unexpectedly executed
    for (NSUInteger i = 0; i < PINOperationQueueTestsMaxOperations * 2; i++) {
        dispatch_group_enter(group);
        [self.queue scheduleOperation:^{
            usleep(1000);
            dispatch_group_leave(group);
        }];
    }
    
    for (NSUInteger i = 0; i < completionFlags.count; i++) {
        dispatch_group_enter(group);
        
        PINOperationBlock operation = ^(id  _Nullable data) {
            for (NSNumber *hasCompletion in completionFlags) {
                if ([hasCompletion boolValue] == NO) {
                    dispatch_group_leave(group);
                }
            }
        };
        
        dispatch_block_t completion = [completionFlags[i] boolValue] == NO ? nil : ^{
            XCTAssert([expectedCompletedIndexSet containsIndex:i]);
            @synchronized (self) {
                [completedIndexSet addIndex:i];
            }
            dispatch_group_leave(group);
        };
        
        [self.queue scheduleOperation:operation
                    withPriority:PINOperationQueuePriorityLow
                      identifier:@"Identifier"
                  coalescingData:nil
             dataCoalescingBlock:nil
                      completion:completion];
    }
#pragma clang diagnostic pop
    
    NSUInteger success = dispatch_group_wait(group, [self timeout]);
    XCTAssert(success == 0, @"Timed out");
    XCTAssert([completedIndexSet isEqual:expectedCompletedIndexSet]);
}

- (void)testCoalescingOperationData
{
    dispatch_group_t group = dispatch_group_create();
    
    NSArray<NSNumber *> *dataset = @[@(100), @(50), @(50), @(100), @(10)];
    NSNumber *expectedData = [dataset sortedArrayUsingSelector:@selector(compare:)][0];
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-retain-cycles"
    // Fill up the queue with dummy operations so we have time to add real ones without them being unexpectedly executed
    for (NSUInteger i = 0; i < PINOperationQueueTestsMaxOperations * 2; i++) {
        dispatch_group_enter(group);
        [self.queue scheduleOperation:^{
            usleep(1000);
            dispatch_group_leave(group);
        }];
    }
    
    for (NSNumber *data in dataset) {
        dispatch_group_enter(group);
        
        PINOperationBlock operation = ^(id _Nullable obj) {
            XCTAssert([expectedData compare:obj] == NSOrderedSame);
        };
        
        PINOperationDataCoalescingBlock dataCoalescingBlock = ^id(id existingData, id newData) {
            NSComparisonResult result = [existingData compare:newData];
            return (result == NSOrderedDescending) ? newData : existingData;
        };
        
        dispatch_block_t completion = ^{
            dispatch_group_leave(group);
        };
        
        [self.queue scheduleOperation:operation
                    withPriority:PINOperationQueuePriorityLow
                      identifier:@"Identifier"
                  coalescingData:data
             dataCoalescingBlock:dataCoalescingBlock
                      completion:completion];
    }
#pragma clang diagnostic pop
    
    NSUInteger success = dispatch_group_wait(group, [self timeout]);
    XCTAssert(success == 0, @"Timed out");
}

- (void)testChangingMaximumNumberOfOperations
{
  PINOperationQueue *queue = [[PINOperationQueue alloc] initWithMaxConcurrentOperations:2];
  [self helperConfirmMaxOperations:2 queue:queue];
  queue.maxConcurrentOperations = 4;
  usleep(10000);
  [self helperConfirmMaxOperations:4 queue:queue];
  queue.maxConcurrentOperations = 2;
  usleep(10000);
  [self helperConfirmMaxOperations:2 queue:queue];
}

@end
