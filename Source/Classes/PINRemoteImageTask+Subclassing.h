//
//  PINRemoteImageTask+Subclassing.h
//  PINRemoteImage
//
//  Created by Garrett Moon on 5/22/17.
//  Copyright © 2017 Pinterest. All rights reserved.
//

#import "PINRemoteImageTask.h"

NS_ASSUME_NONNULL_BEGIN

@interface PINRemoteImageTask (Subclassing)

- (NSMutableDictionary *)l_callbackBlocks;
- (BOOL)l_cancelWithUUID:(NSUUID *)UUID;

@end

NS_ASSUME_NONNULL_END
