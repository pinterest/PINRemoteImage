//
//  PINRemoteImageManagerResult.m
//  Pods
//
//  Created by Garrett Moon on 3/9/15.
//
//

#import "PINRemoteImageManagerResult.h"

@implementation PINRemoteImageManagerResult

+ (instancetype)imageResultWithImage:(PINImage *)image
                       animatedImage:(FLAnimatedImage *)animatedImage
                       requestLength:(NSTimeInterval)requestLength
                               error:(NSError *)error
                          resultType:(PINRemoteImageResultType)resultType
                                UUID:(NSUUID *)uuid
                         urlResponse:(NSURLResponse *)response
{
    return [self imageResultWithImage:image
                        animatedImage:animatedImage
                        requestLength:requestLength
                                error:error
                           resultType:resultType
                                 UUID:uuid
                          urlResponse:response
                 renderedImageQuality:1.0];
}

+ (instancetype)imageResultWithImage:(PINImage *)image
                       animatedImage:(nullable FLAnimatedImage *)animatedImage
                       requestLength:(NSTimeInterval)requestLength
                               error:(NSError *)error
                          resultType:(PINRemoteImageResultType)resultType
                                UUID:(NSUUID *)uuid
                         urlResponse:(NSURLResponse *)response
                renderedImageQuality:(CGFloat)renderedImageQuality
{
    return [[self alloc] initWithImage:image
                         animatedImage:animatedImage
                         requestLength:requestLength
                                 error:error
                            resultType:resultType
                                  UUID:uuid
                           urlResponse:response
                  renderedImageQuality:renderedImageQuality];
}

- (instancetype)initWithImage:(PINImage *)image
                animatedImage:(FLAnimatedImage *)animatedImage
                requestLength:(NSTimeInterval)requestLength
                        error:(NSError *)error
                   resultType:(PINRemoteImageResultType)resultType
                         UUID:(NSUUID *)uuid
                  urlResponse:(NSURLResponse *)response
         renderedImageQuality:(CGFloat)renderedImageQuality
{
    if (self = [super init]) {
        _image = image;
        _animatedImage = animatedImage;
        _requestDuration = requestLength;
        _error = error;
        _resultType = resultType;
        _UUID = uuid;
        _renderedImageQuality = renderedImageQuality;
        _response = response;
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
    description = [description stringByAppendingString:@"\n"];
    description = [description stringByAppendingString:[NSString stringWithFormat:@"UUID: %f", self.renderedImageQuality]];
    if ([self.response isKindOfClass:[NSHTTPURLResponse class]]) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)self.response;
        description = [description stringByAppendingString:@"\n"];
        description = [description stringByAppendingString:[NSString stringWithFormat:@"Status Code: %d", httpResponse.statusCode]];
    }
    return description;
}

@end
