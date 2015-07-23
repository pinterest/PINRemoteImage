//
//  NSData+ImageDetectors.h
//  Pods
//
//  Created by Garrett Moon on 11/19/14.
//
//

#import <Foundation/Foundation.h>

@interface NSData (ImageDetectors)

- (BOOL)isGIF;
#if __has_include(<webp/decode.h>)
- (BOOL)isWebP;
#endif

@end
