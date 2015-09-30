//
//  NSData+ImageDetectors.h
//  Pods
//
//  Created by Garrett Moon on 11/19/14.
//
//

#import <Foundation/Foundation.h>

@interface NSData (PINImageDetectors)

- (BOOL)pin_isGIF;
#if __has_include(<webp/decode.h>)
- (BOOL)pin_isWebP;
#endif

@end

@interface NSData (PINImageDetectors_Deprecated)

- (BOOL)isGIF __attribute((deprecated("use pin_isGIF")));
#if __has_include(<webp/decode.h>)
- (BOOL)isWebP __attribute((deprecated("use pin_isWebP")));
#endif

@end
