//
//  PINImage+AlternativeTypes.m
//  PINRemoteImage
//
//  Created by Brandon Li on 6/22/21.
//

#import "PINImage+AlternativeTypes.h"

#import <objc/runtime.h>

@implementation PINImage (AlternativeTypes)

- (nullable NSData *)pin_encodedImageData {
  return (NSData *)objc_getAssociatedObject(self, @selector(pin_encodedImageData));
}

- (void)setPin_encodedImageData:(NSData *)data {
  objc_setAssociatedObject(self, @selector(pin_encodedImageData), data, OBJC_ASSOCIATION_RETAIN);
}

- (nullable id<PINImageCustomDecoder>)pin_encodedImageDataCustomDecoder {
  return (id<PINImageCustomDecoder>)objc_getAssociatedObject(
      self, @selector(pin_encodedImageDataCustomDecoder));
}

- (void)setPin_encodedImageDataCustomDecoder:(id<PINImageCustomDecoder>)customDecoder {
  objc_setAssociatedObject(self, @selector(pin_encodedImageDataCustomDecoder), customDecoder,
                           OBJC_ASSOCIATION_RETAIN);
}

- (nullable PINImage *)pin_decodedImageUsingCustomDecoderWithSize:(CGSize)size {
  return [self.pin_encodedImageDataCustomDecoder imageFromData:self.pin_encodedImageData
                                                       targetSize:size];
}

@end
