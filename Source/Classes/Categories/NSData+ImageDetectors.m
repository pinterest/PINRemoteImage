//
//  NSData+ImageDetectors.m
//  Pods
//
//  Created by Garrett Moon on 11/19/14.
//
//

#import "NSData+ImageDetectors.h"

#if PIN_WEBP
    #if SWIFT_PACKAGE
        @import libwebp;
    #else
        #import "webp/demux.h"
    #endif
#endif

@implementation NSData (PINImageDetectors)

- (BOOL)pin_isGIF
{
    const NSInteger length = 3;
    Byte firstBytes[length];
    if ([self length] >= length) {
        [self getBytes:&firstBytes length:length];
        //G, I, F
        if (firstBytes[0] == 0x47 && firstBytes[1] == 0x49 && firstBytes[2] == 0x46) {
            return YES;
        }
    }
    return NO;
}

#define BREAK_IF_INVALID(position) if (position >= length) break;

static inline BOOL advancePositionWithCount(NSUInteger *position, NSUInteger length, NSUInteger count)
{
    if (*position + count >= length) {
        return NO;
    }
    *position = *position + count;
    
    return YES;
}

static inline BOOL advancePositionWithBytes(NSUInteger *position, Byte *bytes, NSUInteger length, NSUInteger count)
{
    BOOL readAgain;
    do {
        readAgain = NO;
        if (*position + count >= length ) {
            return NO;
        }
        *position = *position + count;
        NSUInteger bytesToAdvance = *(bytes + *position);
        if (bytesToAdvance == 0xFF) {
            readAgain = YES;
            count = 0;
        }
        // Advance the byte read as well.
        bytesToAdvance++;
        
        if (*position + bytesToAdvance >= length) {
            return NO;
        }
        *position = *position + bytesToAdvance;
    } while (readAgain);
    
    return YES;
}

- (BOOL)pin_isAnimatedGIF
{
    if ([self pin_isGIF] == NO) {
        return NO;
    }
    
    Byte *bytes = (Byte *)self.bytes;
    NSUInteger length = self.length;
    NSUInteger position = 0;
    NSUInteger GCECount = 0;
    
    while (bytes && position < length) {
        // Look for Graphic Control Extension
        if (*(bytes + position) == 0x21) {
            if (!advancePositionWithCount(&position, length, 1)) break;
            if (*(bytes + position) == 0xF9) {
                GCECount++;
                if (GCECount > 1) {
                    break;
                }
                // Found GCE, advance to image. Next byte is size of GCE
                if (!advancePositionWithBytes(&position, bytes, length, 1)) break;
                // Advance 1 for 00 at the end of GCE
                if (!advancePositionWithCount(&position, length, 1)) break;
                // Advance image descriptor
                if (!advancePositionWithCount(&position, length, 11)) break;
                // Advance image
                if (!advancePositionWithBytes(&position, bytes, length, 0)) break;
                // Advance 1 for 00 at the end of image
                if (!advancePositionWithCount(&position, length, 1)) break;
            }
            continue;
        }
        if (!advancePositionWithCount(&position, length, 1)) break;
    }
    
    return GCECount > 1;
}

#if PIN_WEBP
- (BOOL)pin_isWebP
{
    const NSInteger length = 12;
    Byte firstBytes[length];
    if ([self length] >= length) {
        [self getBytes:&firstBytes length:length];
        //R, I, F, F, -, -, -, -, W, E, B, P
        if (firstBytes[0] == 0x52 && firstBytes[1] == 0x49 && firstBytes[2] == 0x46 && firstBytes[3] == 0x46 && firstBytes[8] == 0x57 && firstBytes[9] == 0x45 && firstBytes[10] == 0x42 && firstBytes[11] == 0x50) {
            return YES;
        }
    }
    return NO;
}

- (BOOL)pin_isAnimatedWebP
{
    WebPBitstreamFeatures features;
    if (WebPGetFeatures([self bytes], [self length], &features) == VP8_STATUS_OK) {
        return features.has_animation;
    }
    
    return NO;
}

#endif

@end
