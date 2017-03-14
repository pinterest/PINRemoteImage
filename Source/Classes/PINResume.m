//
//  PINResume.m
//  PINRemoteImage
//
//  Created by Garrett Moon on 3/10/17.
//  Copyright © 2017 Pinterest. All rights reserved.
//

#import "PINResume.h"

@implementation PINResume

+ (PINResume *)resumeData:(NSData *)resumeData ifRange:(NSString *)ifRange totalBytes:(NSUInteger)totalBytes
{
    PINResume *resume = [[PINResume alloc] initWithResumeData:resumeData ifRange:ifRange totalBytes:totalBytes];
    return resume;
}

- (PINResume *)initWithResumeData:(NSData *)resumeData ifRange:(NSString *)ifRange totalBytes:(NSUInteger)totalBytes
{
    if (self = [super init]) {
        _resumeData = resumeData;
        _ifRange = ifRange;
        _totalBytes = totalBytes;
    }
    return self;
}

@end
