//
//  PINRemoteImageManagerResult.m
//  Pods
//
//  Created by Garrett Moon on 3/9/15.
//
//

#import "PINRemoteImageManagerResult.h"

@implementation PINRemoteImageManagerResult

+ (nonnull instancetype)imageResultWithImage:(nullable PINImage *)image
                   alternativeRepresentation:(nullable id)alternativeRepresentation
                               requestLength:(NSTimeInterval)requestLength
                                  resultType:(PINRemoteImageResultType)resultType
                                        UUID:(nullable NSUUID *)uuid
                                    response:(nullable NSURLResponse *)response
                                       error:(nullable NSError *)error
{
    return [self imageResultWithImage:image
            alternativeRepresentation:alternativeRepresentation
                        requestLength:requestLength
                           resultType:resultType
                                 UUID:uuid
                             response:response
                                error:error
                 renderedImageQuality:1.0];
}

+ (nonnull instancetype)imageResultWithImage:(nullable PINImage *)image
                   alternativeRepresentation:(nullable id)alternativeRepresentation
                               requestLength:(NSTimeInterval)requestLength
                                  resultType:(PINRemoteImageResultType)resultType
                                        UUID:(nullable NSUUID *)uuid
                                    response:(nullable NSURLResponse *)response
                                       error:(nullable NSError *)error
                        bytesSavedByResuming:(NSUInteger)bytesSavedByResuming
{
    return [[self alloc] initWithImage:image
             alternativeRepresentation:alternativeRepresentation
                         requestLength:requestLength
                                 error:error
                            resultType:resultType
                                  UUID:uuid
                              response:response
                  renderedImageQuality:1.0
                  bytesSavedByResuming:bytesSavedByResuming];
}

+ (nonnull instancetype)imageResultWithImage:(nullable PINImage *)image
                   alternativeRepresentation:(nullable id)alternativeRepresentation
                               requestLength:(NSTimeInterval)requestLength
                                  resultType:(PINRemoteImageResultType)resultType
                                        UUID:(nullable NSUUID *)uuid
                                    response:(nullable NSURLResponse *)response
                                       error:(nullable NSError *)error
                        renderedImageQuality:(CGFloat)renderedImageQuality
{
    return [[self alloc] initWithImage:image
             alternativeRepresentation:alternativeRepresentation
                         requestLength:requestLength
                                 error:error
                            resultType:resultType
                                  UUID:uuid
                              response:response
                  renderedImageQuality:renderedImageQuality
                  bytesSavedByResuming:0];
}

- (instancetype)initWithImage:(PINImage *)image
    alternativeRepresentation:(id)alternativeRepresentation
                requestLength:(NSTimeInterval)requestLength
                        error:(NSError *)error
                   resultType:(PINRemoteImageResultType)resultType
                         UUID:(NSUUID *)uuid
                     response:(NSURLResponse *)response
         renderedImageQuality:(CGFloat)renderedImageQuality
         bytesSavedByResuming:(NSUInteger)bytesSavedByResuming;
{
    if (self = [super init]) {
        _image = image;
        _alternativeRepresentation = alternativeRepresentation;
        _requestDuration = requestLength;
        _error = error;
        _resultType = resultType;
        _UUID = uuid;
        _response = response;
        _renderedImageQuality = renderedImageQuality;
        _bytesSavedByResuming = bytesSavedByResuming;
    }
    return self;
}

- (NSString *)description
{
    NSString *description = [super description];
    description = [description stringByAppendingString:[NSString stringWithFormat:@"image: %@", self.image]];
    description = [description stringByAppendingString:@"\n"];
    description = [description stringByAppendingString:[NSString stringWithFormat:@"alternativeRepresentation: %@", self.alternativeRepresentation]];
    description = [description stringByAppendingString:@"\n"];
    description = [description stringByAppendingString:[NSString stringWithFormat:@"requestDuration: %f", self.requestDuration]];
    description = [description stringByAppendingString:@"\n"];
    description = [description stringByAppendingString:[NSString stringWithFormat:@"error: %@", self.error]];
    description = [description stringByAppendingString:@"\n"];
    description = [description stringByAppendingString:[NSString stringWithFormat:@"resultType: %lu", (unsigned long)self.resultType]];
    description = [description stringByAppendingString:@"\n"];
    description = [description stringByAppendingString:[NSString stringWithFormat:@"UUID: %@", self.UUID]];
    description = [description stringByAppendingString:@"\n"];
    description = [description stringByAppendingString:[NSString stringWithFormat:@"response: %@", self.response]];
    description = [description stringByAppendingString:@"\n"];
    description = [description stringByAppendingString:[NSString stringWithFormat:@"renderedImageQuality: %f", self.renderedImageQuality]];
    description = [description stringByAppendingString:@"\n"];
    description = [description stringByAppendingString:[NSString stringWithFormat:@"bytesSavedByResuming: %lu", (unsigned long)self.bytesSavedByResuming]];
    return description;
}

@end
