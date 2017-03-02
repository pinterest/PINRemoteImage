//
//  NSURLSessionDataTask+SupportsResume.h
//  PINRemoteImage
//
//  Created by Garrett Moon on 3/1/17.
//  Copyright © 2017 Pinterest. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSURLSessionDataTask (SupportsResume)

@property (nonatomic, assign) BOOL supportsResume;

@end
