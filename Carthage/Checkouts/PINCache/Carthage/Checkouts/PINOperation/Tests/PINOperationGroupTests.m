//
//  PINOperationGroupTests.m
//  PINOperationQueue
//
//  Created by Garrett Moon on 10/12/16.
//  Copyright © 2016 Pinterest. All rights reserved.
//

#import <XCTest/XCTest.h>

#import <pthread.h>

#import <PINOperation/PINOperation.h>

static NSTimeInterval PINOperationGroupTestBlockTimeout = 20;

@interface PINOperationGroupTests : XCTestCase

@property PINOperationQueue *queue;

@end

@implementation PINOperationGroupTests

- (dispatch_time_t)timeout
{
  return dispatch_time(DISPATCH_TIME_NOW, (int64_t)(PINOperationGroupTestBlockTimeout * NSEC_PER_SEC));
}

- (void)setUp {
  [super setUp];
  self.queue = [[PINOperationQueue alloc] initWithMaxConcurrentOperations:5];
}

- (void)tearDown {
  // Put teardown code here. This method is called after the invocation of each test method in the class.
  [super tearDown];
}

- (void)testAllOperationsRunBeforeCompletion
{
  __block NSUInteger operationsRun = 0;
  PINOperationGroup *group = [PINOperationGroup asyncOperationGroupWithQueue:self.queue];
  
  for (NSUInteger idx = 0; idx < 100; idx++) {
    __weak typeof(self) weakSelf = self;
    [group addOperation:^{
      typeof(self) strongSelf = weakSelf;
      @synchronized (strongSelf) {
        operationsRun++;
      }
    }];
  }
  
  XCTestExpectation *completionRun = [self expectationWithDescription:@"Completion Run"];
  
  __weak typeof(self) weakSelf = self;
  [group setCompletion:^{
    typeof(self) strongSelf = weakSelf;
    @synchronized (strongSelf) {
      XCTAssert(operationsRun == 100, @"Not all operations were run before completion");
    }
    [completionRun fulfill];
  }];
  
  [group start];
  
  [self waitForExpectationsWithTimeout:PINOperationGroupTestBlockTimeout handler:nil];
}

- (void)testWaitUntilOperationsComplete
{
  __block NSUInteger operationsRun = 0;
  PINOperationGroup *group = [PINOperationGroup asyncOperationGroupWithQueue:self.queue];
  
  for (NSUInteger idx = 0; idx < 100; idx++) {
    __weak typeof(self) weakSelf = self;
    [group addOperation:^{
      typeof(self) strongSelf = weakSelf;
      @synchronized (strongSelf) {
        operationsRun++;
      }
    }];
  }
  
  [group waitUntilComplete];
  
  @synchronized (self) {
    XCTAssert(operationsRun == 100, @"All operations should be run");
  }
}

- (void)testCancelation
{
  __block NSUInteger operationsRun = 0;
  PINOperationGroup *group = [PINOperationGroup asyncOperationGroupWithQueue:self.queue];
  
  const NSUInteger operationsToRun = 100;
  
  for (NSUInteger idx = 0; idx < operationsToRun; idx++) {
    __weak typeof(self) weakSelf = self;
    [group addOperation:^{
      usleep(10000);
      typeof(self) strongSelf = weakSelf;
      @synchronized (strongSelf) {
        operationsRun++;
      }
    }];
  }
  
  [group setCompletion:^{
    XCTAssert(NO, @"completion should not be run");
  }];
  
  [group start];
  [group cancel];
  
  usleep(10000 * operationsToRun);
  
  @synchronized (self) {
    XCTAssert(operationsRun < operationsToRun, @"All operations should not be run.");
  }
}

@end
