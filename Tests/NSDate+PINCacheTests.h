#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSDate (PINCacheTests)

/** Swizzles +[NSDate date] to always return the specified date. */
+ (void)startMockingDateWithDate:(NSDate *)date;

/** Stops swizzling +[NSDate date] and returns to original implementation */
+ (void)stopMockingDate;

@end

NS_ASSUME_NONNULL_END
