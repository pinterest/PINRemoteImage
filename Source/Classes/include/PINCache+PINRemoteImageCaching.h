//
//  PINCache+PINRemoteImageCaching.h
//  Pods
//
//  Created by Aleksei Shevchenko on 7/28/16.
//
//

#if SWIFT_PACKAGE
@import PINCache;
#else
#import "external/PINCache/Source/PINCache.h"
#endif

#import "Source/Classes/include/PINRemoteImageCaching.h"
#import "Source/Classes/include/PINRemoteImageManager.h"

@interface PINCache (PINRemoteImageCaching) <PINRemoteImageCaching>

@end

@interface PINRemoteImageManager (PINCache)

@property (nonatomic, nullable, readonly) PINCache <PINRemoteImageCaching> *pinCache;

@end
