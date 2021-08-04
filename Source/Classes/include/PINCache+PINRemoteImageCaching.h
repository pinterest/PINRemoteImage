//
//  PINCache+PINRemoteImageCaching.h
//  Pods
//
//  Created by Aleksei Shevchenko on 7/28/16.
//
//

#if !__has_include(<PINCache/PINCache.h>)
#import "PINCache.h"
#else
#import <PINCache/PINCache.h>
#endif

#import "PINRemoteImageCaching.h"
#import "PINRemoteImageManager.h"

@interface PINCache (PINRemoteImageCaching) <PINRemoteImageCaching>

@end

@interface PINRemoteImageManager (PINCache)

@property (nonatomic, nullable, readonly) PINCache <PINRemoteImageCaching> *pinCache;

@end
