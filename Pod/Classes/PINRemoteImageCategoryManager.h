//
//  PINRemoteImageCategory.h
//  Pods
//
//  Created by Garrett Moon on 11/4/14.
//
//

#import <UIKit/UIKit.h>

#import "PINRemoteImageManager.h"

@protocol PINRemoteImageCategory;

/**
 PINRemoteImageCategoryManager is a class that handles subclassing image display classes. UIImage+PINRemoteImage, UIButton+PINRemoteImage, etc, all delegate their work to this class. If you'd like to create a category to display an image on a view, you should mimic one of the above categories.
 */

@interface PINRemoteImageCategoryManager : NSObject

+ (void)setImageOnView:(id <PINRemoteImageCategory>)view
               fromURL:(NSURL *)url;

+ (void)setImageOnView:(id <PINRemoteImageCategory>)view
               fromURL:(NSURL *)url
      placeholderImage:(UIImage *)placeholderImage;

+ (void)setImageOnView:(id <PINRemoteImageCategory>)view
               fromURL:(NSURL *)url
      placeholderImage:(UIImage *)placeholderImage
            completion:(PINRemoteImageManagerImageCompletion)completion;

+ (void)setImageOnView:(id <PINRemoteImageCategory>)view
               fromURL:(NSURL *)url
            completion:(PINRemoteImageManagerImageCompletion)completion;

+ (void)setImageOnView:(id <PINRemoteImageCategory>)view
               fromURL:(NSURL *)url
          processorKey:(NSString *)processorKey
             processor:(PINRemoteImageManagerImageProcessor)processor;

+ (void)setImageOnView:(id <PINRemoteImageCategory>)view
               fromURL:(NSURL *)url
      placeholderImage:(UIImage *)placeholderImage
          processorKey:(NSString *)processorKey
             processor:(PINRemoteImageManagerImageProcessor)processor;

+ (void)setImageOnView:(id <PINRemoteImageCategory>)view
               fromURL:(NSURL *)url
          processorKey:(NSString *)processorKey
             processor:(PINRemoteImageManagerImageProcessor)processor
            completion:(PINRemoteImageManagerImageCompletion)completion;

+ (void)setImageOnView:(id <PINRemoteImageCategory>)view
              fromURLs:(NSArray *)urls
      placeholderImage:(UIImage *)placeholderImage
          processorKey:(NSString *)processorKey
             processor:(PINRemoteImageManagerImageProcessor)processor
            completion:(PINRemoteImageManagerImageCompletion)completion;

+ (void)setImageOnView:(id <PINRemoteImageCategory>)view
              fromURLs:(NSArray *)urls;

+ (void)setImageOnView:(id <PINRemoteImageCategory>)view
              fromURLs:(NSArray *)urls
      placeholderImage:(UIImage *)placeholderImage;

+ (void)setImageOnView:(id <PINRemoteImageCategory>)view
              fromURLs:(NSArray *)urls
      placeholderImage:(UIImage *)placeholderImage
            completion:(PINRemoteImageManagerImageCompletion)completion;

+ (void)cancelImageDownloadOnView:(id <PINRemoteImageCategory>)view;

+ (NSUUID *)downloadImageOperationUUIDOnView:(id <PINRemoteImageCategory>)view;

+ (void)setDownloadImageOperationUUID:(NSUUID *)downloadImageOperationUUID onView:(id <PINRemoteImageCategory>)view;

+ (BOOL)updateWithProgressOnView:(id <PINRemoteImageCategory>)view;

+ (void)setUpdateWithProgressOnView:(BOOL)updateWithProgress onView:(id <PINRemoteImageCategory>)view;

@end

/**
 Protocol to implement on UIView subclasses to support PINRemoteImage
 */
@protocol PINRemoteImageCategory <NSObject>

//Call manager

/**
 Set the image from the given URL.
 
 @param url NSURL to fetch from.
 */
- (void)pin_setImageFromURL:(NSURL *)url;

/**
 Set the image from the given URL and set placeholder image while image at URL is being retrieved.
 
 @param url NSURL to fetch from.
 @param placeholderImage UIImage to set on the view while the image at URL is being retrieved.
 */
- (void)pin_setImageFromURL:(NSURL *)url placeholderImage:(UIImage *)placeholderImage;

/**
 Set the image from the given URL and call completion when finished.
 
 @param url NSURL to fetch from.
 @param completion Called when url has been retrieved and set on view.
 */
- (void)pin_setImageFromURL:(NSURL *)url completion:(PINRemoteImageManagerImageCompletion)completion;

/**
 Set the image from the given URL, set placeholder while image at url is being retrieved and call completion when finished.
 
 @param url NSURL to fetch from.
 @param placeholderImage UIImage to set on the view while the image at URL is being retrieved.
 @param completion Called when url has been retrieved and set on view.
 */
- (void)pin_setImageFromURL:(NSURL *)url placeholderImage:(UIImage *)placeholderImage completion:(PINRemoteImageManagerImageCompletion)completion;

/**
 Retrieve the image from the given URL, process it using the passed in processor block and set result on view.
 
 @param url NSURL to fetch from.
 @param processorKey NSString key to uniquely identify processor. Used in caching.
 @param processor PINRemoteImageManagerImageProcessor processor block which should return the processed image.
 */
- (void)pin_setImageFromURL:(NSURL *)url processorKey:(NSString *)processorKey processor:(PINRemoteImageManagerImageProcessor)processor;

/**
 Set placeholder on view and retrieve the image from the given URL, process it using the passed in processor block and set result on view.
 
 @param url NSURL to fetch from.
 @param placeholderImage UIImage to set on the view while the image at URL is being retrieved.
 @param processorKey NSString key to uniquely identify processor. Used in caching.
 @param processor PINRemoteImageManagerImageProcessor processor block which should return the processed image.
 */
- (void)pin_setImageFromURL:(NSURL *)url placeholderImage:(UIImage *)placeholderImage processorKey:(NSString *)processorKey processor:(PINRemoteImageManagerImageProcessor)processor;

/**
 Retrieve the image from the given URL, process it using the passed in processor block and set result on view. Call completion after image has been fetched, processed and set on view.
 
 @param url NSURL to fetch from.
 @param processorKey NSString key to uniquely identify processor. Used in caching.
 @param processor PINRemoteImageManagerImageProcessor processor block which should return the processed image.
 @param completion Called when url has been retrieved and set on view.
 */
- (void)pin_setImageFromURL:(NSURL *)url processorKey:(NSString *)processorKey processor:(PINRemoteImageManagerImageProcessor)processor completion:(PINRemoteImageManagerImageCompletion)completion;

/**
 Set placeholder on view and retrieve the image from the given URL, process it using the passed in processor block and set result on view. Call completion after image has been fetched, processed and set on view.
 
 @param url NSURL to fetch from.
 @param placeholderImage UIImage to set on the view while the image at URL is being retrieved.
 @param processorKey NSString key to uniquely identify processor. Used in caching.
 @param processor PINRemoteImageManagerImageProcessor processor block which should return the processed image.
 @param completion Called when url has been retrieved and set on view.
 */
- (void)pin_setImageFromURL:(NSURL *)url placeholderImage:(UIImage *)placeholderImage processorKey:(NSString *)processorKey processor:(PINRemoteImageManagerImageProcessor)processor completion:(PINRemoteImageManagerImageCompletion)completion;

/**
 Retrieve one of the images at the passed in URLs depending on previous network performance and set result on view.
 
 @param urls NSArray of NSURLs sorted in increasing quality
 */
- (void)pin_setImageFromURLs:(NSArray *)urls;

/**
 Set placeholder on view and retrieve one of the images at the passed in URLs depending on previous network performance and set result on view.
 
 @param urls NSArray of NSURLs sorted in increasing quality
 @param placeholderImage UIImage to set on the view while the image at URL is being retrieved.
 */
- (void)pin_setImageFromURLs:(NSArray *)urls placeholderImage:(UIImage *)placeholderImage;

/**
 Set placeholder on view and retrieve one of the images at the passed in URLs depending on previous network performance and set result on view. Call completion after image has been fetched and set on view.
 
 @param urls NSArray of NSURLs sorted in increasing quality
 @param placeholderImage UIImage to set on the view while the image at URL is being retrieved.
 @param completion Called when url has been retrieved and set on view.
 */
- (void)pin_setImageFromURLs:(NSArray *)urls placeholderImage:(UIImage *)placeholderImage completion:(PINRemoteImageManagerImageCompletion)completion;

/**
 Cancels the image download. Guarantees that previous setImage calls will *not* have their results set on the image view after calling this (as opposed to PINRemoteImageManager which does not guarantee cancellation).
 */
- (void)pin_cancelImageDownload;

/**
 Returns the NSUUID associated with any PINRemoteImage task currently running on the view.
 
 @return NSUUID associated with any PINRemoteImage task currently running on the view.
 */
- (NSUUID *)pin_downloadImageOperationUUID;

/**
 Set the current NSUUID associated with a PINRemoteImage task running on the view.
 
 @param downloadImageOperationUUID NSUUID associated with a PINRemoteImage task.
 */
- (void)pin_setDownloadImageOperationUUID:(NSUUID *)downloadImageOperationUUID;

/**
 Whether the view should update with progress images (such as those provided by progressive JPEG images).
 
 @return BOOL value indicating whether the view should update with progress images
 */
@property (nonatomic, assign) BOOL pin_updateWithProgress;

//Handle
- (void)pin_setPlaceholderWithImage:(UIImage *)image;
- (void)pin_updateUIWithImage:(UIImage *)image animatedImage:(FLAnimatedImage *)animatedImage;
- (void)pin_clearImages;
- (BOOL)pin_ignoreGIFs;

@optional

- (PINRemoteImageManagerDownloadOptions)pin_defaultOptions;

@end

/**
 Deprecated version of protocol to implement on UIView subclasses to support PINRemoteImage
 */
@protocol PINRemoteImageCategory_Deprecated <NSObject>

//Call manager

/**
 Set the image from the given URL.

 @param url NSURL to fetch from.
 */
- (void)setImageFromURL:(NSURL *)url __attribute((deprecated("use pin_setImageFromURL:")));

/**
 Set the image from the given URL and set placeholder image while image at URL is being retrieved.

 @param url NSURL to fetch from.
 @param placeholderImage UIImage to set on the view while the image at URL is being retrieved.
 */
- (void)setImageFromURL:(NSURL *)url placeholderImage:(UIImage *)placeholderImage __attribute((deprecated("use pin_setImageFromURL:placeholderImage:")));

/**
 Set the image from the given URL and call completion when finished.

 @param url NSURL to fetch from.
 @param completion Called when url has been retrieved and set on view.
 */
- (void)setImageFromURL:(NSURL *)url completion:(PINRemoteImageManagerImageCompletion)completion __attribute((deprecated("use pin_setImageFromURL:completion:")));

/**
 Set the image from the given URL, set placeholder while image at url is being retrieved and call completion when finished.

 @param url NSURL to fetch from.
 @param placeholderImage UIImage to set on the view while the image at URL is being retrieved.
 @param completion Called when url has been retrieved and set on view.
 */
- (void)setImageFromURL:(NSURL *)url placeholderImage:(UIImage *)placeholderImage completion:(PINRemoteImageManagerImageCompletion)completion __attribute((deprecated("use pin_setImageFromURL:placeholderImage:completion:")));

/**
 Retrieve the image from the given URL, process it using the passed in processor block and set result on view.

 @param url NSURL to fetch from.
 @param processorKey NSString key to uniquely identify processor. Used in caching.
 @param processor PINRemoteImageManagerImageProcessor processor block which should return the processed image.
 */
- (void)setImageFromURL:(NSURL *)url processorKey:(NSString *)processorKey processor:(PINRemoteImageManagerImageProcessor)processor __attribute((deprecated("use pin_setImageFromURL:processorKey:processor:")));

/**
 Set placeholder on view and retrieve the image from the given URL, process it using the passed in processor block and set result on view.

 @param url NSURL to fetch from.
 @param placeholderImage UIImage to set on the view while the image at URL is being retrieved.
 @param processorKey NSString key to uniquely identify processor. Used in caching.
 @param processor PINRemoteImageManagerImageProcessor processor block which should return the processed image.
 */
- (void)setImageFromURL:(NSURL *)url placeholderImage:(UIImage *)placeholderImage processorKey:(NSString *)processorKey processor:(PINRemoteImageManagerImageProcessor)processor __attribute((deprecated("use pin_setImageFromURL:placeholderImage:processorKey:processor:")));

/**
 Retrieve the image from the given URL, process it using the passed in processor block and set result on view. Call completion after image has been fetched, processed and set on view.

 @param url NSURL to fetch from.
 @param processorKey NSString key to uniquely identify processor. Used in caching.
 @param processor PINRemoteImageManagerImageProcessor processor block which should return the processed image.
 @param completion Called when url has been retrieved and set on view.
 */
- (void)setImageFromURL:(NSURL *)url processorKey:(NSString *)processorKey processor:(PINRemoteImageManagerImageProcessor)processor completion:(PINRemoteImageManagerImageCompletion)completion __attribute((deprecated("use pin_completion:")));

/**
 Set placeholder on view and retrieve the image from the given URL, process it using the passed in processor block and set result on view. Call completion after image has been fetched, processed and set on view.

 @param url NSURL to fetch from.
 @param placeholderImage UIImage to set on the view while the image at URL is being retrieved.
 @param processorKey NSString key to uniquely identify processor. Used in caching.
 @param processor PINRemoteImageManagerImageProcessor processor block which should return the processed image.
 @param completion Called when url has been retrieved and set on view.
 */
- (void)setImageFromURL:(NSURL *)url placeholderImage:(UIImage *)placeholderImage processorKey:(NSString *)processorKey processor:(PINRemoteImageManagerImageProcessor)processor completion:(PINRemoteImageManagerImageCompletion)completion __attribute((deprecated("use pin_completion:")));

/**
 Retrieve one of the images at the passed in URLs depending on previous network performance and set result on view.

 @param urls NSArray of NSURLs sorted in increasing quality
 */
- (void)setImageFromURLs:(NSArray *)urls __attribute((deprecated("use pin_setImageFromURLs:")));

/**
 Set placeholder on view and retrieve one of the images at the passed in URLs depending on previous network performance and set result on view.

 @param urls NSArray of NSURLs sorted in increasing quality
 @param placeholderImage UIImage to set on the view while the image at URL is being retrieved.
 */
- (void)setImageFromURLs:(NSArray *)urls placeholderImage:(UIImage *)placeholderImage __attribute((deprecated("use pin_setImageFromURLs:placeholderImage:")));

/**
 Set placeholder on view and retrieve one of the images at the passed in URLs depending on previous network performance and set result on view. Call completion after image has been fetched and set on view.

 @param urls NSArray of NSURLs sorted in increasing quality
 @param placeholderImage UIImage to set on the view while the image at URL is being retrieved.
 @param completion Called when url has been retrieved and set on view.
 */
- (void)setImageFromURLs:(NSArray *)urls placeholderImage:(UIImage *)placeholderImage completion:(PINRemoteImageManagerImageCompletion)completion __attribute((deprecated("use pin_setImageFromURLs:(NSArray *)urls placeholderImage:completion:")));

/**
 Cancels the image download. Guarantees that previous setImage calls will *not* have their results set on the image view after calling this (as opposed to PINRemoteImageManager which does not guarantee cancellation).
 */
- (void)cancelImageDownload __attribute((deprecated("use pin_cancelImageDownload")));

/**
 Returns the NSUUID associated with any PINRemoteImage task currently running on the view.

 @return NSUUID associated with any PINRemoteImage task currently running on the view.
 */
- (NSUUID *)downloadImageOperationUUID __attribute((deprecated("use pin_downloadImageOperationUUID")));

/**
 Set the current NSUUID associated with a PINRemoteImage task running on the view.

 @param downloadImageOperationUUID NSUUID associated with a PINRemoteImage task.
 */
- (void)setDownloadImageOperationUUID:(NSUUID *)downloadImageOperationUUID __attribute((deprecated("use pin_setDownloadImageOperationUUID:")));

/**
 Whether the view should update with progress images (such as those provided by progressive JPEG images).

 @return BOOL value indicating whether the view should update with progress images
 */
@property (nonatomic, assign) BOOL updateWithProgress __attribute((deprecated("use pin_@property (nonatomic, assign) BOOL updateWithProgress")));

//Handle
- (void)setPlaceholderWithImage:(UIImage *)image __attribute((deprecated("use pin_setPlaceholderWithImage:")));
- (void)updateUIWithImage:(UIImage *)image animatedImage:(FLAnimatedImage *)animatedImage __attribute((deprecated("use pin_updateUIWithImage:animatedImage:")));
- (void)clearImages __attribute((deprecated("use pin_clearImages")));
- (BOOL)ignoreGIFs __attribute((deprecated("use pin_ignoreGIFs")));

@end
