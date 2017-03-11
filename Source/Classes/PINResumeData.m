//
//  PINResumeData.m
//  PINRemoteImage
//
//  Created by Garrett Moon on 3/10/17.
//  Copyright © 2017 Pinterest. All rights reserved.
//

#import "PINResumeData.h"

@implementation PINResumeData

+ (PINResumeData *)resumeData:(NSData *)resumeData ifRange:(NSString *)ifRange totalBytes:(NSUInteger)totalBytes
{
    PINResumeData *resume = [[PINResumeData alloc] initWithResumeData:resumeData ifRange:ifRange totalBytes:totalBytes];
    return resume;
}

- (PINResumeData *)initWithResumeData:(NSData *)resumeData ifRange:(NSString *)ifRange totalBytes:(NSUInteger)totalBytes
{
    if (self = [super init]) {
        _resumeData = resumeData;
        _ifRange = ifRange;
        _totalBytes = totalBytes;
    }
    return self;
}

@end
