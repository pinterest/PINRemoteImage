#import "NSDate+PINCacheTests.h"

#import <objc/runtime.h>

static NSDate *PINCacheTestsSwizzedDate = nil;

@implementation NSDate (PINCacheTests)

+ (void)startMockingDateWithDate:(NSDate *)date
{
    // If already swizzled, just replace the static date.
    BOOL alreadySwizzled = (PINCacheTestsSwizzedDate != nil);
    PINCacheTestsSwizzedDate = date;
    if (alreadySwizzled) { return; }

    SEL originalSelector = @selector(date);
    SEL swizzledSelector = @selector(swizzled_date);

    Method originalMethod = class_getClassMethod(self, originalSelector);
    Method swizzledMethod = class_getClassMethod(self, swizzledSelector);

    Class class = object_getClass((id)self);

    if (class_addMethod(class,
                        originalSelector,
                        method_getImplementation(swizzledMethod),
                        method_getTypeEncoding(swizzledMethod))) {
        class_replaceMethod(class,
                            swizzledSelector,
                            method_getImplementation(originalMethod),
                            method_getTypeEncoding(originalMethod));
    } else {
        method_exchangeImplementations(originalMethod, swizzledMethod);
    }
}

+ (void)stopMockingDate
{
    Method originalMethod = class_getClassMethod(self, @selector(date));
    Method swizzledMethod = class_getClassMethod(self, @selector(swizzled_date));
    method_exchangeImplementations(swizzledMethod, originalMethod);
    PINCacheTestsSwizzedDate = nil;
}

+ (instancetype)swizzled_date
{
    return PINCacheTestsSwizzedDate;
}

@end
