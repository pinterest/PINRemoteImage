//
//  PINRemoteImageMacros.h
//  PINRemoteImage
//

#import <TargetConditionals.h>

#ifndef PINRemoteImageMacros_h
#define PINRemoteImageMacros_h

#define PIN_TARGET_IOS (TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR || TARGET_OS_TV)
#define PIN_TARGET_MAC (TARGET_OS_MAC)

#define PINRemoteImageLogging                0
#if PINRemoteImageLogging
#define PINLog(args...) NSLog(args)
#else
#define PINLog(args...)
#endif

#if __has_include(<FLAnimatedImage/FLAnimatedImage.h>)
#define USE_FLANIMATED_IMAGE    1
#else
#define USE_FLANIMATED_IMAGE    0
#define FLAnimatedImage NSObject
#endif

#if __has_include(<PINCache/PINCache.h>)
#define USE_PINCACHE    1
#else
#define USE_PINCACHE    0
#endif

#if PIN_TARGET_IOS
#define PINImage     UIImage
#define PINImageView UIImageView
#define PINButton    UIButton
#define PINNSOperationSupportsBlur (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_8_0)
#define PINNSURLSessionTaskSupportsPriority (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_8_0)
#elif PIN_TARGET_MAC
#define PINImage     NSImage
#define PINImageView NSImageView
#define PINButton    NSButton
#define PINNSOperationSupportsBlur (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber10_10)
#define PINNSURLSessionTaskSupportsPriority (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber10_10)
#endif

#define PINWeakify(var) __weak typeof(var) PINWeak_##var = var;

#define PINStrongify(var)                                                                                           \
_Pragma("clang diagnostic push") _Pragma("clang diagnostic ignored \"-Wshadow\"") __strong typeof(var) var = \
PINWeak_##var;                                                                                           \
_Pragma("clang diagnostic pop")

#define BlockAssert(condition, desc, ...)	\
do {				\
__PRAGMA_PUSH_NO_EXTRA_ARG_WARNINGS \
if (!(condition)) {		\
[[NSAssertionHandler currentHandler] handleFailureInMethod:_cmd \
object:strongSelf file:[NSString stringWithUTF8String:__FILE__] \
lineNumber:__LINE__ description:(desc), ##__VA_ARGS__]; \
}				\
__PRAGMA_POP_NO_EXTRA_ARG_WARNINGS \
} while(0);

#endif /* PINRemoteImageMacros_h */
