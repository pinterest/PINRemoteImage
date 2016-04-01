//
//  UIButton+PINRemoteImage.m
//  Pods
//
//  Created by Garrett Moon on 8/18/14.
//
//

#import "PINButton+PINRemoteImage.h"

@implementation PINButton (PINRemoteImage)

- (void)pin_setImageFromURL:(NSURL *)url
{
    [PINRemoteImageCategoryManager setImageOnView:self fromURL:url];
}

- (void)pin_setImageFromURL:(NSURL *)url placeholderImage:(PINImage *)placeholderImage
{
    [PINRemoteImageCategoryManager setImageOnView:self fromURL:url placeholderImage:placeholderImage];
}

- (void)pin_setImageFromURL:(NSURL *)url completion:(PINRemoteImageManagerImageCompletion)completion
{
    [PINRemoteImageCategoryManager setImageOnView:self fromURL:url completion:completion];
}

- (void)pin_setImageFromURL:(NSURL *)url placeholderImage:(PINImage *)placeholderImage completion:(PINRemoteImageManagerImageCompletion)completion
{
    [PINRemoteImageCategoryManager setImageOnView:self fromURL:url placeholderImage:placeholderImage completion:completion];
}

- (void)pin_setImageFromURL:(NSURL *)url processorKey:(NSString *)processorKey processor:(PINRemoteImageManagerImageProcessor)processor
{
    [PINRemoteImageCategoryManager setImageOnView:self fromURL:url processorKey:processorKey processor:processor];
}

- (void)pin_setImageFromURL:(NSURL *)url placeholderImage:(PINImage *)placeholderImage processorKey:(NSString *)processorKey processor:(PINRemoteImageManagerImageProcessor)processor
{
    [PINRemoteImageCategoryManager setImageOnView:self fromURL:url placeholderImage:placeholderImage processorKey:processorKey processor:processor];
}

- (void)pin_setImageFromURL:(NSURL *)url processorKey:(NSString *)processorKey processor:(PINRemoteImageManagerImageProcessor)processor completion:(PINRemoteImageManagerImageCompletion)completion
{
    [PINRemoteImageCategoryManager setImageOnView:self fromURL:url processorKey:processorKey processor:processor completion:completion];
}

- (void)pin_setImageFromURL:(NSURL *)url placeholderImage:(PINImage *)placeholderImage processorKey:(NSString *)processorKey processor:(PINRemoteImageManagerImageProcessor)processor completion:(PINRemoteImageManagerImageCompletion)completion
{
    [PINRemoteImageCategoryManager setImageOnView:self fromURLs:url?@[url]:nil placeholderImage:placeholderImage processorKey:processorKey processor:processor completion:completion];
}

- (void)pin_setImageFromURLs:(NSArray <NSURL *> *)urls
{
    [PINRemoteImageCategoryManager setImageOnView:self fromURLs:urls];
}

- (void)pin_setImageFromURLs:(NSArray <NSURL *> *)urls placeholderImage:(PINImage *)placeholderImage
{
    [PINRemoteImageCategoryManager setImageOnView:self fromURLs:urls placeholderImage:placeholderImage];
}

- (void)pin_setImageFromURLs:(NSArray <NSURL *> *)urls placeholderImage:(PINImage *)placeholderImage completion:(PINRemoteImageManagerImageCompletion)completion
{
    [PINRemoteImageCategoryManager setImageOnView:self fromURLs:urls placeholderImage:placeholderImage completion:completion];
}

#pragma mark - Operation Management

- (void)pin_cancelImageDownload
{
    [PINRemoteImageCategoryManager cancelImageDownloadOnView:self];
}

- (NSUUID *)pin_downloadImageOperationUUID
{
    return [PINRemoteImageCategoryManager downloadImageOperationUUIDOnView:self];
}

- (void)pin_setDownloadImageOperationUUID:(NSUUID *)downloadImageOperationUUID
{
    [PINRemoteImageCategoryManager setDownloadImageOperationUUID:downloadImageOperationUUID onView:self];
}

- (BOOL)pin_updateWithProgress
{
    return [PINRemoteImageCategoryManager updateWithProgressOnView:self];
}

- (void)setPin_updateWithProgress:(BOOL)updateWithProgress
{
    [PINRemoteImageCategoryManager setUpdateWithProgressOnView:updateWithProgress onView:self];
}

- (void)pin_setPlaceholderWithImage:(PINImage *)image
{
#if PIN_TARGET_IOS
    [self setImage:image forState:UIControlStateNormal];
#elif PIN_TARGET_MAC
    [self setImage:image];
#endif
}

- (void)pin_updateUIWithImage:(PINImage *)image animatedImage:(FLAnimatedImage *)animatedImage
{
    if (image) {
#if PIN_TARGET_IOS
        [self setImage:image forState:UIControlStateNormal];
        [self setNeedsLayout];
#elif PIN_TARGET_MAC
        [self setImage:image];
        [self setNeedsLayout:YES];
#endif
    }
}

- (void)pin_clearImages
{
#if PIN_TARGET_IOS
    [self setImage:nil forState:UIControlStateNormal];
    [self setBackgroundImage:nil forState:UIControlStateNormal];
    [self setNeedsLayout];
#elif PIN_TARGET_MAC
    [self setImage:nil];
    [self setBackgroundImage:nil]
    [self setNeedsLayout:YES];
#endif
}

- (BOOL)pin_ignoreGIFs
{
    return YES;
}

#pragma mark - Background Images

- (void)pin_setBackgroundImageFromURL:(NSURL *)url
{
    [PINRemoteImageCategoryManager setBackgroundImageOnView:self fromURL:url];
}

- (void)pin_setBackgroundImageFromURL:(NSURL *)url placeholderImage:(PINImage *)placeholderImage
{
    [PINRemoteImageCategoryManager setBackgroundImageOnView:self fromURL:url placeholderImage:placeholderImage];
}

- (void)pin_setBackgroundImageFromURL:(NSURL *)url completion:(PINRemoteImageManagerImageCompletion)completion
{
    [PINRemoteImageCategoryManager setBackgroundImageOnView:self fromURL:url completion:completion];
}

- (void)pin_setBackgroundImageFromURL:(NSURL *)url placeholderImage:(PINImage *)placeholderImage completion:(PINRemoteImageManagerImageCompletion)completion
{
    [PINRemoteImageCategoryManager setBackgroundImageOnView:self fromURL:url placeholderImage:placeholderImage completion:completion];
}

- (void)pin_setBackgroundImageFromURL:(NSURL *)url processorKey:(NSString *)processorKey processor:(PINRemoteImageManagerImageProcessor)processor
{
    [PINRemoteImageCategoryManager setBackgroundImageOnView:self fromURL:url processorKey:processorKey processor:processor];
}

- (void)pin_setBackgroundImageFromURL:(NSURL *)url placeholderImage:(PINImage *)placeholderImage processorKey:(NSString *)processorKey processor:(PINRemoteImageManagerImageProcessor)processor
{
    [PINRemoteImageCategoryManager setBackgroundImageOnView:self fromURL:url placeholderImage:placeholderImage processorKey:processorKey processor:processor];
}

- (void)pin_setBackgroundImageFromURL:(NSURL *)url processorKey:(NSString *)processorKey processor:(PINRemoteImageManagerImageProcessor)processor completion:(PINRemoteImageManagerImageCompletion)completion
{
    [PINRemoteImageCategoryManager setBackgroundImageOnView:self fromURL:url processorKey:processorKey processor:processor completion:completion];
}

- (void)pin_setBackgroundImageFromURL:(NSURL *)url placeholderImage:(PINImage *)placeholderImage processorKey:(NSString *)processorKey processor:(PINRemoteImageManagerImageProcessor)processor completion:(PINRemoteImageManagerImageCompletion)completion
{
    [PINRemoteImageCategoryManager setBackgroundImageOnView:self fromURLs:url?@[url]:nil placeholderImage:placeholderImage processorKey:processorKey processor:processor completion:completion];
}

- (void)pin_setBackgroundImageFromURLs:(NSArray <NSURL *> *)urls
{
    [PINRemoteImageCategoryManager setBackgroundImageOnView:self fromURLs:urls];
}

- (void)pin_setBackgroundImageFromURLs:(NSArray <NSURL *> *)urls placeholderImage:(PINImage *)placeholderImage
{
    [PINRemoteImageCategoryManager setBackgroundImageOnView:self fromURLs:urls placeholderImage:placeholderImage];
}

- (void)pin_setBackgroundImageFromURLs:(NSArray <NSURL *> *)urls placeholderImage:(PINImage *)placeholderImage completion:(PINRemoteImageManagerImageCompletion)completion
{
    [PINRemoteImageCategoryManager setBackgroundImageOnView:self fromURLs:urls placeholderImage:placeholderImage completion:completion];
}


- (void)pin_setBackgroundPlaceholderWithImage:(PINImage *)image
{
#if PIN_TARGET_IOS
    [self setBackgroundImage:image forState:UIControlStateNormal];
#elif PIN_TARGET_MAC
    [self setImage:image];
    [self sizeToFit];
#endif
}

- (void)pin_updateUIWithBackgroundImage:(PINImage *)image animatedImage:(FLAnimatedImage *)animatedImage
{
    if (image) {
#if PIN_TARGET_IOS
        [self setBackgroundImage:image forState:UIControlStateNormal];
        [self setNeedsLayout];
#elif PIN_TARGET_MAC
        [self setImage:image];
        [self setNeedsLayout:YES];
#endif
    }
}

@end
