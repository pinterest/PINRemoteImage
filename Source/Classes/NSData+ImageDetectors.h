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
- (BOOL)pin_isAnimatedGIF;
#if PIN_WEBP
- (BOOL)pin_isWebP;
- (BOOL)pin_isAnimatedWebP;
#endif

@end
