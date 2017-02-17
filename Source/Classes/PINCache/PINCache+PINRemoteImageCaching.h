//
//  PINCache+PINRemoteImageCaching.h
//  Pods
//
//  Created by Aleksei Shevchenko on 7/28/16.
//
//

#import <PINCache/PINCache.h>
#import <PINRemoteImage/PINRemoteImageManager.h>

#import "PINRemoteImageCaching.h"

@interface PINCache (PINRemoteImageCaching) <PINRemoteImageCaching>

@end

@interface PINRemoteImageManager (PINCache)

@property (nonatomic, readonly, nonnull) PINCache *cache;

@end
