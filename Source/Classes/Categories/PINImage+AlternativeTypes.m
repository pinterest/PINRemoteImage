//
//  PINImage+AlternativeTypes.m
//  PINRemoteImage
//
//  Created by Brandon Li on 6/22/21.
//

#import "PINImage+AlternativeTypes.h"

#import <objc/runtime.h>

@implementation PINImage (AlternativeTypes)

+ (void)pin_registerCustomDecoder:(id<PINImageCustomDecoder>)customDecoder {
  NSMutableArray<id<PINImageCustomDecoder>> *decoders = [PINImage pin_decoders];
  [decoders addObject:customDecoder];
  objc_setAssociatedObject(self, @selector(pin_registerCustomDecoder:), decoders, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

}

- (nullable NSData *)pin_encodedImageData {
  return (NSData *)objc_getAssociatedObject(self, @selector(pin_encodedImageData));
}

- (void)setPin_encodedImageData:(NSData *)data {
  objc_setAssociatedObject(self, @selector(pin_encodedImageData), data, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (nullable PINImage *)pin_decodedImageUsingCustomDecodersWithSize:(CGSize)size {
  NSMutableArray<id<PINImageCustomDecoder>> *decoders = [PINImage pin_decoders];
  for (id<PINImageCustomDecoder> decoder in decoders) {
    if ([decoder canRender:self.pin_encodedImageData]) {
      return [decoder imageFromData:self.pin_encodedImageData targetSize:size];
    }
  }

  return nil;
}

#pragma mark - Private

+ (NSMutableArray<id<PINImageCustomDecoder>> *)pin_decoders {
  return objc_getAssociatedObject(self, @selector(pin_registerCustomDecoder:)) ?: [NSMutableArray array];
}

@end
