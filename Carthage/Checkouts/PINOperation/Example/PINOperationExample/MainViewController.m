//
//  MainViewController.m
//  PINOperationExample
//
//  Created by Martin Púčik on 02/05/2020.
//  Copyright © 2020 Pinterest. All rights reserved.
//

#import "MainViewController.h"
#import <PINOperation/PINOperation.h>
//#import <pthread.h>

@interface MainViewController ()
@property (nonatomic, strong) PINOperationQueue *queue;
@end

@implementation MainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.queue = [[PINOperationQueue alloc] initWithMaxConcurrentOperations:5];

    const NSUInteger operationCount = 100;
    dispatch_group_t group = dispatch_group_create();

    for (NSUInteger count = 0; count < operationCount; count++) {
        dispatch_group_enter(group);
        [self.queue scheduleOperation:^{
            dispatch_group_leave(group);
        } withPriority:PINOperationQueuePriorityDefault];
    }

    NSUInteger success = dispatch_group_wait(group, [self timeout]);
    NSAssert(success == 0, @"Timed out before completing 100 operations");
}

- (dispatch_time_t)timeout {
    return dispatch_time(DISPATCH_TIME_NOW, (int64_t)(20 * NSEC_PER_SEC));
}

@end
