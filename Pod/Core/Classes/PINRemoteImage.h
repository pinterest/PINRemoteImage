//
//  PINRemoteImage.h
//  Pods
//
//  Created by Garrett Moon on 8/17/14.
//
//

#ifndef Pods_PINRemoteImage_h
#define Pods_PINRemoteImage_h

#define PINRemoteImageLogging                0
#if PINRemoteImageLogging
#define PINLog(args...) NSLog(args)
#else
#define PINLog(args...)
#endif

#import "PINFLAnimatedImageCheck.h"

#if !TARGET_OS_IPHONE
#define UIImage                 NSImage
#endif

#import "PINRemoteImageManager.h"

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

#endif
