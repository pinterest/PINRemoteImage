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
           alternativeRepresentation:(id)alternativeRepresentation
                       requestLength:(NSTimeInterval)requestLength
                               error:(NSError *)error
                          resultType:(PINRemoteImageResultType)resultType
                                UUID:(NSUUID *)uuid
{
    return [self imageResultWithImage:image
            alternativeRepresentation:alternativeRepresentation
                        requestLength:requestLength
                                error:error
                           resultType:resultType
                                 UUID:uuid
                             progress:1.0];
}

+ (instancetype)imageResultWithImage:(PINImage *)image
           alternativeRepresentation:(id)alternativeRepresentation
                       requestLength:(NSTimeInterval)requestLength
                               error:(NSError *)error
                          resultType:(PINRemoteImageResultType)resultType
                                UUID:(NSUUID *)uuid
                            progress:(CGFloat)progress
{
    return [[self alloc] initWithImage:image
             alternativeRepresentation:alternativeRepresentation
                         requestLength:requestLength
                                 error:error
                            resultType:resultType
                                  UUID:uuid
                              progress:progress];
}

- (instancetype)initWithImage:(PINImage *)image
    alternativeRepresentation:(id)alternativeRepresentation
                requestLength:(NSTimeInterval)requestLength
                        error:(NSError *)error
                   resultType:(PINRemoteImageResultType)resultType
                         UUID:(NSUUID *)uuid
                     progress:(CGFloat)progress
{
    if (self = [super init]) {
        _image = image;
        _alternativeRepresentation = alternativeRepresentation;
        _requestDuration = requestLength;
        _error = error;
        _resultType = resultType;
        _UUID = uuid;
        _progress = progress;
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
    description = [description stringByAppendingString:[NSString stringWithFormat:@"UUID: %@", self.progress]];
    return description;
}

@end
