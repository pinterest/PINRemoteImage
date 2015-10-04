//
//  UIButton+PINRemoteImage.m
//  Pods
//
//  Created by Garrett Moon on 8/18/14.
//
//

#import "UIButton+PINRemoteImage.h"

@implementation UIButton (PINRemoteImage)

- (void)pin_setImageFromURL:(NSURL *)url
{
    [PINRemoteImageCategoryManager setImageOnView:self fromURL:url];
}

- (void)pin_setImageFromURL:(NSURL *)url placeholderImage:(UIImage *)placeholderImage
{
    [PINRemoteImageCategoryManager setImageOnView:self fromURL:url placeholderImage:placeholderImage];
}

- (void)pin_setImageFromURL:(NSURL *)url completion:(PINRemoteImageManagerImageCompletion)completion
{
    [PINRemoteImageCategoryManager setImageOnView:self fromURL:url completion:completion];
}

- (void)pin_setImageFromURL:(NSURL *)url placeholderImage:(UIImage *)placeholderImage completion:(PINRemoteImageManagerImageCompletion)completion
{
    [PINRemoteImageCategoryManager setImageOnView:self fromURL:url placeholderImage:placeholderImage completion:completion];
}

- (void)pin_setImageFromURL:(NSURL *)url processorKey:(NSString *)processorKey processor:(PINRemoteImageManagerImageProcessor)processor
{
    [PINRemoteImageCategoryManager setImageOnView:self fromURL:url processorKey:processorKey processor:processor];
}

- (void)pin_setImageFromURL:(NSURL *)url placeholderImage:(UIImage *)placeholderImage processorKey:(NSString *)processorKey processor:(PINRemoteImageManagerImageProcessor)processor
{
    [PINRemoteImageCategoryManager setImageOnView:self fromURL:url placeholderImage:placeholderImage processorKey:processorKey processor:processor];
}

- (void)pin_setImageFromURL:(NSURL *)url processorKey:(NSString *)processorKey processor:(PINRemoteImageManagerImageProcessor)processor completion:(PINRemoteImageManagerImageCompletion)completion
{
    [PINRemoteImageCategoryManager setImageOnView:self fromURL:url processorKey:processorKey processor:processor completion:completion];
}

- (void)pin_setImageFromURL:(NSURL *)url placeholderImage:(UIImage *)placeholderImage processorKey:(NSString *)processorKey processor:(PINRemoteImageManagerImageProcessor)processor completion:(PINRemoteImageManagerImageCompletion)completion
{
    [PINRemoteImageCategoryManager setImageOnView:self fromURLs:@[url] placeholderImage:placeholderImage processorKey:processorKey processor:processor completion:completion];
}

- (void)pin_setImageFromURLs:(NSArray *)urls
{
    [PINRemoteImageCategoryManager setImageOnView:self fromURLs:urls];
}

- (void)pin_setImageFromURLs:(NSArray *)urls placeholderImage:(UIImage *)placeholderImage
{
    [PINRemoteImageCategoryManager setImageOnView:self fromURLs:urls placeholderImage:placeholderImage];
}

- (void)pin_setImageFromURLs:(NSArray *)urls placeholderImage:(UIImage *)placeholderImage completion:(PINRemoteImageManagerImageCompletion)completion
{
    [PINRemoteImageCategoryManager setImageOnView:self fromURLs:urls placeholderImage:placeholderImage completion:completion];
}

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

- (void)pin_setPlaceholderWithImage:(UIImage *)image
{
    [self setImage:image forState:UIControlStateNormal];
}

- (void)pin_updateUIWithImage:(UIImage *)image animatedImage:(FLAnimatedImage *)animatedImage
{
    if (image) {
        [self setImage:image forState:UIControlStateNormal];
        [self setNeedsLayout];
    }
}

- (void)pin_clearImages
{
    [self setImage:nil forState:UIControlStateNormal];
    [self setNeedsLayout];
}

- (BOOL)pin_ignoreGIFs
{
    return YES;
}

@end

@implementation UIButton (PINRemoteImage_Deprecated)

- (void)setImageFromURL:(NSURL *)url
{
    [self pin_setImageFromURL:url];
}

- (void)setImageFromURL:(NSURL *)url placeholderImage:(UIImage *)placeholderImage
{
    [self pin_setImageFromURL:url placeholderImage:placeholderImage];
}

- (void)setImageFromURL:(NSURL *)url completion:(PINRemoteImageManagerImageCompletion)completion
{
    [self pin_setImageFromURL:url completion:completion];
}

- (void)setImageFromURL:(NSURL *)url placeholderImage:(UIImage *)placeholderImage completion:(PINRemoteImageManagerImageCompletion)completion
{
    [self pin_setImageFromURL:url placeholderImage:placeholderImage completion:completion];
}

- (void)setImageFromURL:(NSURL *)url processorKey:(NSString *)processorKey processor:(PINRemoteImageManagerImageProcessor)processor
{
    [self pin_setImageFromURL:url processorKey:processorKey processor:processor];
}

- (void)setImageFromURL:(NSURL *)url placeholderImage:(UIImage *)placeholderImage processorKey:(NSString *)processorKey processor:(PINRemoteImageManagerImageProcessor)processor
{
    [self pin_setImageFromURL:url placeholderImage:placeholderImage processorKey:processorKey processor:processor];
}

- (void)setImageFromURL:(NSURL *)url processorKey:(NSString *)processorKey processor:(PINRemoteImageManagerImageProcessor)processor completion:(PINRemoteImageManagerImageCompletion)completion
{
    [self pin_setImageFromURL:url processorKey:processorKey processor:processor completion: completion];
}

- (void)setImageFromURL:(NSURL *)url placeholderImage:(UIImage *)placeholderImage processorKey:(NSString *)processorKey processor:(PINRemoteImageManagerImageProcessor)processor completion:(PINRemoteImageManagerImageCompletion)completion
{
    [self pin_setImageFromURL:url placeholderImage:placeholderImage processorKey:processorKey processor:processor completion:completion];
}

- (void)setImageFromURLs:(NSArray *)urls
{
    [self pin_setImageFromURLs:urls];
}

- (void)setImageFromURLs:(NSArray *)urls placeholderImage:(UIImage *)placeholderImage
{
    [self pin_setImageFromURLs:urls placeholderImage:placeholderImage];
}

- (void)setImageFromURLs:(NSArray *)urls placeholderImage:(UIImage *)placeholderImage completion:(PINRemoteImageManagerImageCompletion)completion
{
    [self pin_setImageFromURLs:urls placeholderImage:placeholderImage completion:completion];
}

- (void)cancelImageDownload
{
    [self pin_cancelImageDownload];
}

- (NSUUID *)downloadImageOperationUUID
{
    return [self pin_downloadImageOperationUUID];
}

- (void)setDownloadImageOperationUUID:(NSUUID *)downloadImageOperationUUID
{
    [self pin_setDownloadImageOperationUUID:downloadImageOperationUUID];
}

- (BOOL)updateWithProgress
{
    return [self pin_updateWithProgress];
}

- (void)setUpdateWithProgress:(BOOL)updateWithProgress
{
    self.pin_updateWithProgress = updateWithProgress;
}

- (void)setPlaceholderWithImage:(UIImage *)image
{
    [self pin_setPlaceholderWithImage:image];
}

- (void)updateUIWithImage:(UIImage *)image animatedImage:(FLAnimatedImage *)animatedImage
{
    [self pin_updateUIWithImage:image animatedImage:animatedImage];
}

- (void)clearImages
{
    [self pin_clearImages];
}

- (BOOL)ignoreGIFs
{
    return [self pin_ignoreGIFs];
}

@end
