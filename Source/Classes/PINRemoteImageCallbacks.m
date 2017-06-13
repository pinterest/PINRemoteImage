//
//  PINRemoteImageCallbacks.m
//  Pods
//
//  Created by Garrett Moon on 3/9/15.
//
//

#import "PINRemoteImageCallbacks.h"

@implementation PINRemoteImageCallbacks

- (instancetype)init
{
  if (self = [super init]) {
    _requestTime = CACurrentMediaTime();
  }
  return self;
}

@end
