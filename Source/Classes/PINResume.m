//
//  PINResume.m
//  PINRemoteImage
//
//  Created by Garrett Moon on 3/10/17.
//  Copyright © 2017 Pinterest. All rights reserved.
//

#import "PINResume.h"

@implementation PINResume

+ (PINResume *)resumeData:(NSData *)resumeData ifRange:(NSString *)ifRange totalBytes:(long long)totalBytes
{
    PINResume *resume = [[PINResume alloc] initWithResumeData:resumeData ifRange:ifRange totalBytes:totalBytes];
    return resume;
}

- (PINResume *)initWithResumeData:(NSData *)resumeData ifRange:(NSString *)ifRange totalBytes:(long long)totalBytes
{
    if (self = [super init]) {
        NSAssert(resumeData.length > 0 && ifRange.length > 0 && totalBytes > 0, @"PINResume must have all fields non-nil and non-zero length.");
        _resumeData = resumeData;
        _ifRange = ifRange;
        _totalBytes = totalBytes;
    }
    return self;
}

@end
