//
//  PINRemoteImageMemoryContainer.h
//  Pods
//
//  Created by Garrett Moon on 3/17/16.
//
//

#import <Foundation/Foundation.h>

#import "Source/Classes/include/PINRemoteImageMacros.h"
#import "Source/Classes/PINRemoteLock.h"

@class PINImage;

@interface PINRemoteImageMemoryContainer : NSObject

@property (nonatomic, strong) PINImage *image;
@property (nonatomic, strong) NSData *data;
@property (nonatomic, strong) PINRemoteLock *lock;

@end
