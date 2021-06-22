//
//  PINImage+AlternativeTypes.h
//  PINRemoteImage
//
//  Created by Brandon Li on 6/22/21.
//

#import <Foundation/Foundation.h>

#import "PINRemoteImageMacros.h"

#if PIN_TARGET_IOS
#import <UIKit/UIKit.h>
#elif PIN_TARGET_MAC
#import <Cocoa/Cocoa.h>
#endif

// A decoder that knows how to convert image data into a PINImage.
@protocol PINImageCustomDecoder

- (PINImage *)imageFromData:(NSData *)imageData targetSize:(CGSize)size;

- (BOOL)canRender:(NSData *)imageData;

@end

@interface PINImage (AlternativeTypes)

// The encoded / compressed form of the image data. The data will only be used
// at least one custom decoder that recognizes this data is registered using
// pin_registerCustomDecoder below.
@property(nonatomic, nullable) NSData *pin_encodedImageData;

// Returns an image of the target size.
- (nullable PINImage *)pin_decodedImageUsingCustomDecodersWithSize:(CGSize)size;

// Registers a custom image decoder type.
+ (void)pin_registerCustomDecoder:(id<PINImageCustomDecoder>)customDecoder;

@end
