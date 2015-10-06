//
//  PINRemoteImageCategory.m
//  Pods
//
//  Created by Garrett Moon on 11/4/14.
//
//

#import "PINRemoteImageCategoryManager.h"

#import <objc/runtime.h>

@implementation PINRemoteImageCategoryManager

+ (void)setImageOnView:(id <PINRemoteImageCategory>)view
               fromURL:(NSURL *)url
{
    [self setImageOnView:view fromURL:url placeholderImage:nil];
}

+ (void)setImageOnView:(id <PINRemoteImageCategory>)view
               fromURL:(NSURL *)url
      placeholderImage:(UIImage *)placeholderImage
{
    [self setImageOnView:view fromURL:url placeholderImage:placeholderImage completion:nil];
}

+ (void)setImageOnView:(id <PINRemoteImageCategory>)view
               fromURL:(NSURL *)url
            completion:(PINRemoteImageManagerImageCompletion)completion
{
    [self setImageOnView:view fromURL:url placeholderImage:nil completion:completion];
}

+ (void)setImageOnView:(id <PINRemoteImageCategory>)view
               fromURL:(NSURL *)url
      placeholderImage:(UIImage *)placeholderImage
            completion:(PINRemoteImageManagerImageCompletion)completion
{
    [self setImageOnView:view
                fromURLs:url?@[url]:nil
        placeholderImage:placeholderImage
            processorKey:nil
               processor:nil
              completion:completion];
}

+ (void)setImageOnView:(id <PINRemoteImageCategory>)view
               fromURL:(NSURL *)url
          processorKey:(NSString *)processorKey
             processor:(PINRemoteImageManagerImageProcessor)processor
{
    [self setImageOnView:view
                 fromURL:url
            processorKey:processorKey
               processor:processor
              completion:nil];
}

+ (void)setImageOnView:(id <PINRemoteImageCategory>)view
               fromURL:(NSURL *)url
      placeholderImage:(UIImage *)placeholderImage
          processorKey:(NSString *)processorKey
             processor:(PINRemoteImageManagerImageProcessor)processor
{
    [self setImageOnView:view
                fromURLs:url?@[url]:nil
        placeholderImage:placeholderImage
            processorKey:processorKey
               processor:processor
              completion:nil];
}

+ (void)setImageOnView:(id <PINRemoteImageCategory>)view
               fromURL:(NSURL *)url
          processorKey:(NSString *)processorKey
             processor:(PINRemoteImageManagerImageProcessor)processor
            completion:(PINRemoteImageManagerImageCompletion)completion
{
    [self setImageOnView:view
                fromURLs:url?@[url]:nil
        placeholderImage:nil
            processorKey:processorKey
               processor:processor
              completion:completion];
}

+ (void)setImageOnView:(id <PINRemoteImageCategory>)view
              fromURLs:(NSArray *)urls
{
    [self setImageOnView:view
                fromURLs:urls
        placeholderImage:nil];
}

+ (void)setImageOnView:(id <PINRemoteImageCategory>)view
              fromURLs:(NSArray *)urls
      placeholderImage:(UIImage *)placeholderImage
{
    [self setImageOnView:view
                fromURLs:urls
        placeholderImage:placeholderImage
              completion:nil];
}

+ (void)setImageOnView:(id <PINRemoteImageCategory>)view
              fromURLs:(NSArray *)urls
      placeholderImage:(UIImage *)placeholderImage
            completion:(PINRemoteImageManagerImageCompletion)completion
{
    return [self setImageOnView:view
                       fromURLs:urls
               placeholderImage:placeholderImage
                   processorKey:nil
                      processor:nil
                     completion:completion];
}

+ (NSUUID *)downloadImageOperationUUIDOnView:(id <PINRemoteImageCategory>)view
{
    return (NSUUID *)objc_getAssociatedObject(view, @selector(downloadImageOperationUUIDOnView:));
}

+ (void)setDownloadImageOperationUUID:(NSUUID *)downloadImageOperationUUID onView:(id <PINRemoteImageCategory>)view
{
    objc_setAssociatedObject(view, @selector(downloadImageOperationUUIDOnView:), downloadImageOperationUUID, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

+ (BOOL)updateWithProgressOnView:(id <PINRemoteImageCategory>)view
{
    return [(NSNumber *)objc_getAssociatedObject(view, @selector(updateWithProgressOnView:)) boolValue];
}

+ (void)setUpdateWithProgressOnView:(BOOL)updateWithProgress onView:(id <PINRemoteImageCategory>)view
{
    objc_setAssociatedObject(view, @selector(updateWithProgressOnView:), [NSNumber numberWithBool:updateWithProgress], OBJC_ASSOCIATION_RETAIN);
}

+ (void)cancelImageDownloadOnView:(id <PINRemoteImageCategory>)view
{
    if ([self downloadImageOperationUUIDOnView:view]) {
        [[PINRemoteImageManager sharedImageManager] cancelTaskWithUUID:[self downloadImageOperationUUIDOnView:view]];
        [self setDownloadImageOperationUUID:nil onView:view];
    }
}

+ (void)setImageOnView:(id <PINRemoteImageCategory>)view
              fromURLs:(NSArray *)urls
      placeholderImage:(UIImage *)placeholderImage
          processorKey:(NSString *)processorKey
             processor:(PINRemoteImageManagerImageProcessor)processor
            completion:(PINRemoteImageManagerImageCompletion)completion
{
    if (![NSThread isMainThread]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self setImageOnView:view
                        fromURLs:urls
                placeholderImage:placeholderImage
                    processorKey:processorKey
                       processor:processor
                      completion:completion];
        });
        return;
    }
    
    [self cancelImageDownloadOnView:view];
    if (urls == nil || urls.count == 0) {
        [view pin_clearImages];
        return;
    }
    
    if (placeholderImage) {
        [view pin_setPlaceholderWithImage:placeholderImage];
    }
    
    PINRemoteImageManagerDownloadOptions options;
    if([view respondsToSelector:@selector(pin_defaultOptions)]) {
        options = [view pin_defaultOptions];
    } else {
        options = PINRemoteImageManagerDownloadOptionsNone;
    }
    
    if ([view pin_ignoreGIFs]) {
        options |= PINRemoteImageManagerDownloadOptionsIgnoreGIFs;
    }
    
    PINRemoteImageManagerImageCompletion internalProgress = nil;
    if ([self updateWithProgressOnView:view] && processorKey.length <= 0 && processor == nil) {
        internalProgress = ^(PINRemoteImageManagerResult *result)
        {
            void (^mainQueue)() = ^{
                //if result.UUID is nil, we returned immediately and want this result
                NSUUID *currentUUID = [self downloadImageOperationUUIDOnView:view];
                if (![currentUUID isEqual:result.UUID] && result.UUID != nil) {
                    return;
                }
                if (result.image) {
                    [view pin_updateUIWithImage:result.image animatedImage:nil];
                }
            };
            if ([NSThread isMainThread]) {
                mainQueue();
            } else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    mainQueue();
                });
            }
        };
    }
    
    PINRemoteImageManagerImageCompletion internalCompletion = ^(PINRemoteImageManagerResult *result)
    {
        void (^mainQueue)() = ^{
            //if result.UUID is nil, we returned immediately and want this result
            NSUUID *currentUUID = [self downloadImageOperationUUIDOnView:view];
            if (![currentUUID isEqual:result.UUID] && result.UUID != nil) {
                return;
            }
            [self setDownloadImageOperationUUID:nil onView:view];
            if (result.error) {
                if (completion) {
                    completion(result);
                }
                return;
            }
            
            [view pin_updateUIWithImage:result.image animatedImage:result.animatedImage];
            
            if (completion) {
                completion(result);
            }
        };
        if ([NSThread isMainThread]) {
            mainQueue();
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                mainQueue();
            });
        }
    };
    
    NSUUID *downloadImageOperationUUID = nil;
    if (urls.count > 1) {
        downloadImageOperationUUID = [[PINRemoteImageManager sharedImageManager] downloadImageWithURLs:urls
                                                                                               options:options
                                                                                              progress:internalProgress
                                                                                            completion:internalCompletion];
    } else if (processorKey.length > 0 && processor) {
        downloadImageOperationUUID = [[PINRemoteImageManager sharedImageManager] downloadImageWithURL:urls[0]
                                                                                              options:options
                                                                                         processorKey:processorKey
                                                                                            processor:processor
                                                                                           completion:internalCompletion];
    } else {
        downloadImageOperationUUID = [[PINRemoteImageManager sharedImageManager] downloadImageWithURL:urls[0]
                                                                                              options:options
                                                                                             progress:internalProgress
                                                                                           completion:internalCompletion];
    }
    
    [self setDownloadImageOperationUUID:downloadImageOperationUUID onView:view];
}

@end
