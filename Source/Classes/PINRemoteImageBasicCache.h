//
//  PINRemoteImageBasicCache.h
//  Pods
//
//  Created by Aleksei Shevchenko on 7/28/16.
//
//

#import <Foundation/Foundation.h>
#import "PINRemoteImageCaching.h"

/**
 *  Simplistic <PINRemoteImageCacheProtocol> wrapper based on NSCache.
 *  not persisting any data on disk
 */
@interface PINRemoteImageBasicCache : NSObject <PINRemoteImageCaching>

@end
