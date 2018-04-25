//
//  PINAlternateRepresentationProvider.m
//  Pods
//
//  Created by Garrett Moon on 3/17/16.
//
//

#import "PINAlternateRepresentationProvider.h"

#import "PINCachedAnimatedImage.h"
#import "NSData+ImageDetectors.h"

@implementation PINAlternateRepresentationProvider

- (id)alternateRepresentationWithData:(NSData *)data options:(PINRemoteImageManagerDownloadOptions)options
{
    if ([data pin_isAnimatedGIF]) {
        return [[PINCachedAnimatedImage alloc] initWithAnimatedImageData:data];
    }
    return nil;
}

@end
