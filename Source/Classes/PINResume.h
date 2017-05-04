//
//  PINResume.h
//  PINRemoteImage
//
//  Created by Garrett Moon on 3/10/17.
//  Copyright © 2017 Pinterest. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface PINResume : NSObject <NSCoding>

- (id)init NS_UNAVAILABLE;
+ (PINResume *)resumeData:(NSData *)resumeData ifRange:(NSString *)ifRange totalBytes:(long long)totalBytes;

@property (nonatomic, strong, readonly) NSData *resumeData;
@property (nonatomic, copy, readonly) NSString *ifRange;
@property (nonatomic, assign, readonly) long long totalBytes;

@end

NS_ASSUME_NONNULL_END
