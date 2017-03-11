//
//  PINResumeData.h
//  PINRemoteImage
//
//  Created by Garrett Moon on 3/10/17.
//  Copyright © 2017 Pinterest. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface PINResumeData : NSObject

- (id)init NS_UNAVAILABLE;
+ (PINResumeData *)resumeData:(NSData *)resumeData ifRange:(NSString *)ifRange totalBytes:(NSUInteger)totalBytes;

@property (nonatomic, strong, readonly) NSData *resumeData;
@property (nonatomic, strong, readonly) NSString *ifRange;
@property (nonatomic, assign, readonly) NSUInteger totalBytes;

@end

NS_ASSUME_NONNULL_END
