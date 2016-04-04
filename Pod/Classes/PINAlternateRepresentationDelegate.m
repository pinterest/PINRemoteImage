//
//  PINAlternateRepresentationDelegate.m
//  Pods
//
//  Created by Garrett Moon on 3/17/16.
//
//

#import "PINAlternateRepresentationDelegate.h"

#import "NSData+ImageDetectors.h"
#if USE_FLANIMATED_IMAGE
#import <FLAnimatedImage/FLAnimatedImage.h>
#endif

@implementation PINAlternateRepresentationDelegate

- (id)alternateRepresentationWithData:(NSData *)data options:(PINRemoteImageManagerDownloadOptions)options
{
#if USE_FLANIMATED_IMAGE
    if ([data pin_isGIF]) {
        return [FLAnimatedImage animatedImageWithGIFData:data];
    }
#endif
    return nil;
}

@end
