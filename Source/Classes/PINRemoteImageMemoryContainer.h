//
//  PINRemoteImageMemoryContainer.h
//  Pods
//
//  Created by Garrett Moon on 3/17/16.
//
//

#import <Foundation/Foundation.h>

#import <PINRemoteImage/PINRemoteImageMacros.h>
#import <PINRemoteImage/PINRemoteImageDataConvertible.h>
#import "PINRemoteLock.h"

@class PINImage;

@interface PINRemoteImageMemoryContainer : NSObject<PINRemoteImageDataConvertible>

@property (nonatomic, strong) PINImage *image;
@property (nonatomic, strong) NSData *data;
@property (nonatomic, strong) PINRemoteLock *lock;

@end
