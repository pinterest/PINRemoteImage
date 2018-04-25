//
//  PINRemoteWeakProxy.h
//  PINRemoteImage
//
//  Created by Garrett Moon on 4/24/18.
//  Copyright © 2018 Pinterest. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PINRemoteWeakProxy : NSProxy

+ (PINRemoteWeakProxy *)weakProxyWithTarget:(id)target;
- (instancetype)initWithTarget:(id)target;

@end
