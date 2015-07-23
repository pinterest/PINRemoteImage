//
//  UIImageView+PINRemoteImage.m
//  Pods
//
//  Created by Garrett Moon on 8/17/14.
//
//

#import "UIImageView+PINRemoteImage.h"

@implementation UIImageView (PINRemoteImage)

- (void)setImageFromURL:(NSURL *)url
{
    [PINRemoteImageCategoryManager setImageOnView:self fromURL:url];
}

- (void)setImageFromURL:(NSURL *)url placeholderImage:(UIImage *)placeholderImage
{
    [PINRemoteImageCategoryManager setImageOnView:self fromURL:url placeholderImage:placeholderImage];
}

- (void)setImageFromURL:(NSURL *)url completion:(PINRemoteImageManagerImageCompletion)completion
{
    [PINRemoteImageCategoryManager setImageOnView:self fromURL:url completion:completion];
}

- (void)setImageFromURL:(NSURL *)url placeholderImage:(UIImage *)placeholderImage completion:(PINRemoteImageManagerImageCompletion)completion
{
    [PINRemoteImageCategoryManager setImageOnView:self fromURL:url placeholderImage:placeholderImage completion:completion];
}

- (void)setImageFromURL:(NSURL *)url processorKey:(NSString *)processorKey processor:(PINRemoteImageManagerImageProcessor)processor
{
    [PINRemoteImageCategoryManager setImageOnView:self fromURL:url processorKey:processorKey processor:processor];
}

- (void)setImageFromURL:(NSURL *)url placeholderImage:(UIImage *)placeholderImage processorKey:(NSString *)processorKey processor:(PINRemoteImageManagerImageProcessor)processor
{
    [PINRemoteImageCategoryManager setImageOnView:self fromURL:url placeholderImage:placeholderImage processorKey:processorKey processor:processor];
}

- (void)setImageFromURL:(NSURL *)url processorKey:(NSString *)processorKey processor:(PINRemoteImageManagerImageProcessor)processor completion:(PINRemoteImageManagerImageCompletion)completion
{
    [PINRemoteImageCategoryManager setImageOnView:self fromURL:url processorKey:processorKey processor:processor completion:completion];
}

- (void)setImageFromURL:(NSURL *)url placeholderImage:(UIImage *)placeholderImage processorKey:(NSString *)processorKey processor:(PINRemoteImageManagerImageProcessor)processor completion:(PINRemoteImageManagerImageCompletion)completion
{
    [PINRemoteImageCategoryManager setImageOnView:self fromURLs:@[url] placeholderImage:placeholderImage processorKey:processorKey processor:processor completion:completion];
}

- (void)setImageFromURLs:(NSArray *)urls
{
    [PINRemoteImageCategoryManager setImageOnView:self fromURLs:urls];
}

- (void)setImageFromURLs:(NSArray *)urls placeholderImage:(UIImage *)placeholderImage
{
    [PINRemoteImageCategoryManager setImageOnView:self fromURLs:urls placeholderImage:placeholderImage];
}

- (void)setImageFromURLs:(NSArray *)urls placeholderImage:(UIImage *)placeholderImage completion:(PINRemoteImageManagerImageCompletion)completion
{
        [PINRemoteImageCategoryManager setImageOnView:self fromURLs:urls placeholderImage:placeholderImage completion:completion];
}

- (void)cancelImageDownload
{
    [PINRemoteImageCategoryManager cancelImageDownloadOnView:self];
}

- (NSUUID *)downloadImageOperationUUID
{
    return [PINRemoteImageCategoryManager downloadImageOperationUUIDOnView:self];
}

- (void)setDownloadImageOperationUUID:(NSUUID *)downloadImageOperationUUID
{
    [PINRemoteImageCategoryManager setDownloadImageOperationUUID:downloadImageOperationUUID onView:self];
}

- (BOOL)updateWithProgress
{
    return [PINRemoteImageCategoryManager updateWithProgressOnView:self];
}

- (void)setUpdateWithProgress:(BOOL)updateWithProgress
{
    [PINRemoteImageCategoryManager setUpdateWithProgressOnView:updateWithProgress onView:self];
}

- (void)setPlaceholderWithImage:(UIImage *)image
{
    self.image = image;
}

- (void)updateUIWithImage:(UIImage *)image animatedImage:(FLAnimatedImage *)animatedImage
{
    if (image) {
        self.image = image;
        [self setNeedsLayout];
    }
}

- (void)clearImages
{
    self.image = nil;
    [self setNeedsLayout];
}

- (BOOL)ignoreGIFs
{
    return YES;
}

@end
