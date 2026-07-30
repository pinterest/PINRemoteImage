//
//  PINProgressiveImage+Private.h
//  PINRemoteImage
//
//  Created by Garrett Moon on 2/9/15.
//
//

#import <PINRemoteImage/PINProgressiveImage.h>

NS_ASSUME_NONNULL_BEGIN

@interface PINProgressiveImage (Private)

/**
 Returns the current data and relinquishes ownership of it, avoiding a copy.

 This is destructive and deliberately kept out of the public header: it must only be
 called once no further data can be appended for this task -- i.e. from the URL
 session completion handler, after every -didReceiveData: for the task has already
 been delivered synchronously on its serial delegate queue. Calling it from any other
 context (e.g. mid-flight, via KVC, or from a debugger) can silently truncate the
 buffer fed to an in-progress incremental image decode.

 @return NSData The data accumulated so far. Returns nil on a second call.
 */
- (nullable NSData *)takeData;

@end

NS_ASSUME_NONNULL_END
