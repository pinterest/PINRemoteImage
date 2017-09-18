//
//  NSURLSessionTask+Timing.h
//  PINRemoteImage
//
//  Created by Garrett Moon on 5/19/17.
//  Copyright © 2017 Pinterest. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSURLSessionTask (Timing)

- (void)PIN_updateStartTime;
- (void)PIN_updateEndTime;
- (CFTimeInterval)PIN_startTime;
- (CFTimeInterval)PIN_endTime;

@end
