//
//  PINRemoteImageBasicCache.h
//  Pods
//
//  Created by Aleksei Shevchenko on 7/28/16.
//
//

#import <Foundation/Foundation.h>
#import <PINRemoteImage/PINRemoteImageCaching.h>

/**
 *  Simplistic <PINRemoteImageCacheProtocol> wrapper based on NSCache.
 *
 *  No data is persisted on disk. The disk cache methods are no-op.
 */
@interface PINRemoteImageBasicCache : NSObject <PINRemoteImageCaching>

@end
