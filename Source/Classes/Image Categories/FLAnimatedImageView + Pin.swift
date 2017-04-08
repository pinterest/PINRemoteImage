//
//  FLAnimatedImageView + Pin.swift
//  PINRemoteImage
//
//  Created by Andrew Breckenridge on 4/8/17.
//  Copyright © 2017 Pinterest. All rights reserved.
//

#if USE_FLANIMATED_IMAGE
import FLAnimatedImageView
import PINRemoteImageCategoryManager

extension Pin where Base: FLAnimatedImageView {
    /**
     Set placeholder on view and retrieve the image from the given URL, process it using the passed in processor block and set result on view. Call completion after image has been fetched, processed and set on view.

     @param url NSURL to fetch from.
     @param placeholderImage PINImage to set on the view while the image at URL is being retrieved.
     @param processorKey NSString key to uniquely identify processor. Used in caching.
     @param processor PINRemoteImageManagerImageProcessor processor block which should return the processed image.
     @param completion Called when url has been retrieved and set on view.
     */
    func setImage(from url: URL,
                  with placeholderImage: PINImage? = .none,
                  at processorKey: String? = .none,
                  with processor: PINRemoteImageManagerImageProcessor? = .none,
                  completion: PINRemoteImageManagerImageCompletion? = .none) {

    }

    /**
     Set placeholder on view and retrieve one of the images at the passed in URLs depending on previous network performance and set result on view. Call completion after image has been fetched and set on view.

     @param urls NSArray of NSURLs sorted in increasing quality
     @param placeholderImage PINImage to set on the view while the image at URL is being retrieved.
     @param completion Called when url has been retrieved and set on view.
     */
    func setImage(from urls: [URL],
                  with placeholderImage: PINImage? = .none,
                  completion: PINRemoteImageManagerImageCompletion? = .none) {

    }

    /**
     Cancels the image download. Guarantees that previous setImage calls will *not* have their results set on the image view after calling this (as opposed to PINRemoteImageManager which does not guarantee cancellation).
     */
    func cancelImageDownload() {

    }

    // TODO (@AndrewSB 2017-04-08): I think this variable should be renamed to not have `UUID` in it's name #redundant
    /**
     Returns the NSUUID associated with any PINRemoteImage task currently running on the view.

     @return NSUUID associated with any PINRemoteImage task currently running on the view.
     */
    var downloadImageOperationUUID: UUID? {
        get {
            return .none
        }
        set {

        }
    }

    /**
     Whether the view should update with progress images (such as those provided by progressive JPEG images).

     @return BOOL value indicating whether the view should update with progress images
     */
    var updateWithProgress: Bool {
        get { return false }
        set {}
    }

    func setPlaceholder(image: PINImage) {

    }

    func updateUI(with remoteImageManagerResult: PINRemoteImageManagerResult) {

    }

    func clearImages() {
        
    }
    
    var ignoreGifs: Bool {
        get { return false }
    }
}
#endif
