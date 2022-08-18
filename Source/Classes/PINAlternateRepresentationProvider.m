//
//  PINAlternateRepresentationProvider.m
//  Pods
//
//  Created by Garrett Moon on 3/17/16.
//
//

#import "Source/Classes/include/PINAlternateRepresentationProvider.h"

#import "Source/Classes/include/PINCachedAnimatedImage.h"
#import "Source/Classes/include/NSData+ImageDetectors.h"

@implementation PINAlternateRepresentationProvider

- (id)alternateRepresentationWithData:(NSData *)data options:(PINRemoteImageManagerDownloadOptions)options
{
#if PIN_WEBP
    if ([data pin_isAnimatedGIF] || [data pin_isAnimatedWebP]) {
        return [[PINCachedAnimatedImage alloc] initWithAnimatedImageData:data];
    }
#else
    if ([data pin_isAnimatedGIF]) {
        return [[PINCachedAnimatedImage alloc] initWithAnimatedImageData:data];
    }
#endif
    return nil;
}

@end
