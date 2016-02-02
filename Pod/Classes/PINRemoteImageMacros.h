//
//  PINRemoteImageMacros.h
//  PINRemoteImage
//

#ifndef PINRemoteImageMacros_h
#define PINRemoteImageMacros_h

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

#ifdef __IPHONE_OS_VERSION_MIN_REQUIRED
#define PINImage     UIImage
#define PINImageView UIImageView
#define PINButton    UIButton
#else
#define PINImage     NSImage
#define PINImageView NSImageView
#define PINButton    NSButton
#endif

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
