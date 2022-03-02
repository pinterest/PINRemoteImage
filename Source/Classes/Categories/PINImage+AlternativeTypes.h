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

// Decodes the given image data into a PINImage of the target size.
- (nullable PINImage *)imageFromData:(nonnull NSData *)imageData targetSize:(CGSize)size;

// Whether this decoder can handle the given image data.
- (BOOL)canRender:(nonnull NSData *)imageData;

@end

@interface PINImage (AlternativeTypes)

// The encoded / compressed form of the image data. Intended to be decoded by
// @c pin_encodedImageDataCustomDecoder.
@property(nonatomic, nullable) NSData *pin_encodedImageData;

// The selected custom decoder to use for the @c pin_encodedImageData.
@property(nonatomic, nullable) id<PINImageCustomDecoder> pin_encodedImageDataCustomDecoder;

// Returns an image of the target size.
- (nullable PINImage *)pin_decodedImageUsingCustomDecoderWithSize:(CGSize)size;

@end
