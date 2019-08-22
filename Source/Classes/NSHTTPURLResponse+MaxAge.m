//
//  NSHTTPURLResponse+MaxAge.m
//
//  Created by Kevin Smith on 6/15/18.
//
//

#import "NSHTTPURLResponse+MaxAge.h"

@implementation NSHTTPURLResponse (MaxAge)

static NSDateFormatter *sharedFormatter;
static dispatch_once_t sharedFormatterToken;

+ (NSDateFormatter *)RFC7231PreferredDateFormatter
{
    dispatch_once(&sharedFormatterToken, ^{
        NSLocale *enUSPOSIXLocale;

        sharedFormatter = [[NSDateFormatter alloc] init];

        enUSPOSIXLocale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];

        [sharedFormatter setLocale:enUSPOSIXLocale];
        [sharedFormatter setDateFormat:@"E, d MMM yyyy HH:mm:ss Z"];

    });
    return sharedFormatter;
}

- (NSNumber *)findMaxAge 
{
    NSDictionary * headerFields = [self allHeaderFields];
    NSNumber *maxAge = nil;

    for (NSString * component in [headerFields[@"Cache-Control"] componentsSeparatedByString:@","]) {
        NSString * trimmed = [[component stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] lowercaseString];

        if ([trimmed isEqualToString:@"no-store"] || [trimmed isEqualToString:@"must-revalidate"] || [trimmed isEqualToString:@"no-cache"]) {
            maxAge = @(0);
            break;
        } else {
            // max-age
            NSArray<NSString *> * split = [trimmed componentsSeparatedByString:@"max-age="];
            if ([split count] == 2) {
                // if the max-age provided is invalid (does not parse into an
                // int), we wind up with 0 which will be treated as do-not-cache.
                // This is the RFC defined behavior for a malformed "expires" header,
                // and while I cannot find any explicit instruction of how to behave
                // with a malformed "max-age" header, it seems like a reasonable approach.
                maxAge = @([split[1] integerValue]);
            } else if ([split count] > 2) {
                // very weird case "maxage=maxage=123"
                maxAge = @(0);
            }
        }
    }

    // If there is a Cache-Control header with the "max-age" directive in the response, the Expires header is ignored.
    if (!maxAge && headerFields[@"Expires"]) {
        NSString * expires = headerFields[@"Expires"];
        NSDate * date = [[NSHTTPURLResponse RFC7231PreferredDateFormatter] dateFromString:expires];

        // Invalid dates (notably "0") or dates in the past must not be cached (RFC7231 5.3)
        maxAge = @((NSInteger) MAX(([date timeIntervalSinceNow]), 0));
    }

    return maxAge;
}

@end
