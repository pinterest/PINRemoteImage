//
//  PINRemoteImageTask+Subclassing.h
//  PINRemoteImage
//
//  Created by Garrett Moon on 5/22/17.
//  Copyright © 2017 Pinterest. All rights reserved.
//

#import "PINRemoteImageTask.h"

@interface PINRemoteImageTask (Subclassing)

- (nonnull NSMutableDictionary *)l_callbackBlocks;
- (BOOL)l_cancelWithUUID:(nonnull NSUUID *)UUID resume:(PINResume * _Nullable * _Nullable)resume;

@end
