//
//  PINRemoteImageManagerResult.m
//  Pods
//
//  Created by Garrett Moon on 3/9/15.
//
//

#import "PINRemoteImageManagerResult.h"

@implementation PINRemoteImageManagerResult

+ (instancetype)imageResultWithImage:(UIImage *)image
                       animatedImage:(FLAnimatedImage *)animatedImage
                       requestLength:(NSTimeInterval)requestLength
                               error:(NSError *)error
                          resultType:(PINRemoteImageResultType)resultType
                                UUID:(NSUUID *)uuid
{
    return [[self alloc] initWithImage:image
                         animatedImage:animatedImage
                         requestLength:requestLength
                                 error:error
                            resultType:resultType
                                  UUID:uuid];
}

- (instancetype)initWithImage:(UIImage *)image
                animatedImage:(FLAnimatedImage *)animatedImage
                requestLength:(NSTimeInterval)requestLength
                        error:(NSError *)error
                   resultType:(PINRemoteImageResultType)resultType
                         UUID:(NSUUID *)uuid {
    if (self = [super init]) {
        _image = image;
        _animatedImage = animatedImage;
        _requestDuration = requestLength;
        _error = error;
        _resultType = resultType;
        _UUID = uuid;
    }
    return self;
}

- (NSString *)description
{
    NSString *description = [super description];
    description = [description stringByAppendingString:[NSString stringWithFormat:@"image: %@", self.image]];
    description = [description stringByAppendingString:@"\n"];
    description = [description stringByAppendingString:[NSString stringWithFormat:@"animatedImage: %@", self.animatedImage]];
    description = [description stringByAppendingString:@"\n"];
    description = [description stringByAppendingString:[NSString stringWithFormat:@"requestDuration: %f", self.requestDuration]];
    description = [description stringByAppendingString:@"\n"];
    description = [description stringByAppendingString:[NSString stringWithFormat:@"error: %@", self.error]];
    description = [description stringByAppendingString:@"\n"];
    description = [description stringByAppendingString:[NSString stringWithFormat:@"resultType: %lu", (unsigned long)self.resultType]];
    description = [description stringByAppendingString:@"\n"];
    description = [description stringByAppendingString:[NSString stringWithFormat:@"UUID: %@", self.UUID]];
    return description;
}

@end
