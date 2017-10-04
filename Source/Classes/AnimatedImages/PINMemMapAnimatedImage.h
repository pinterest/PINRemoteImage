//
//  PINMemMapAnimatedImage.h
//  Pods
//
//  Created by Garrett Moon on 3/18/16.
//
//

#import <Foundation/Foundation.h>

#if PIN_TARGET_IOS
#import <UIKit/UIKit.h>
#elif PIN_TARGET_MAC
#import <Cocoa/Cocoa.h>
#endif

#import "PINAnimatedImage.h"
#import "PINRemoteImageMacros.h"

#define PINMemMapAnimatedImageDebug  0

/**
 PINMemMapAnimatedImage is a class which decodes GIFs to memory mapped files on disk. Like PINRemoteImageManager,
 it will only decode a GIF one time, regardless of the number of the number of PINMemMapAnimatedImages created with
 the same NSData.
 
 PINMemMapAnimatedImage's are also decoded chunks at a time, writing each chunk to a separate file. This allows callback
 and playback to start before the GIF is completely decoded. If a frame is requested beyond what has been processed,
 nil will be returned. Because a fileReady is called on each chunk completion, you can pause playback if you hit a nil
 frame until you receive another fileReady call.
 
 Internally, PINMemMapAnimatedImage attempts to keep only the files it needs open – the last file associated with the requested
 frame and the one after (to prime).
 
 It's important to note that until infoCompletion is called, it is unsafe to access many of the methods on PINMemMapAnimatedImage.
 */
@interface PINMemMapAnimatedImage : PINAnimatedImage <PINAnimatedImage>

- (instancetype)initWithAnimatedImageData:(NSData *)animatedImageData NS_DESIGNATED_INITIALIZER;

/**
 A block to be called on when GIF info has been processed. Status will == PINAnimatedImageStatusInfoProcessed
 */
@property (nonatomic, strong, readwrite) PINAnimatedImageInfoReady infoCompletion;
/**
 A block to be called whenever a new file is done being processed. You can start (or resume) playback when you
 get this callback, though it's possible for playback to catch up to the decoding and you'll need to pause.
 */
@property (nonatomic, strong, readwrite) dispatch_block_t fileReady;
/**
 A block to be called when the animated image is fully decoded and written to disk.
 */
@property (nonatomic, strong, readwrite) dispatch_block_t animatedImageReady;

/**
 The current status of the animated image.
 */
@property (nonatomic, assign, readwrite) PINAnimatedImageStatus status;

/**
 A helper function which references status to check if the coverImage is ready.
 */
@property (nonatomic, readonly) BOOL coverImageReady;
/**
 A helper function which references status to check if playback is ready.
 */
@property (nonatomic, readonly) BOOL playbackReady;
/**
 The first frame / cover image of the animated image.
 @warning Access to this property before status == PINAnimatedImageStatusInfoProcessed is undefined. You can check coverImageReady too.
 */
@property (nonatomic, readonly) PINImage *coverImage;
/**
 The total duration of one loop of playback.
 @warning Access to this property before status == PINAnimatedImageStatusInfoProcessed is undefined.
 */
@property (nonatomic, readonly) CFTimeInterval totalDuration;
/**
 The number of times to loop the animated image. Returns 0 if looping should occur infinitely.
 @warning Access to this property before status == PINAnimatedImageStatusInfoProcessed is undefined.
 */
@property (nonatomic, readonly) size_t loopCount;
/**
 The total number of frames in the animated image.
 @warning Access to this property before status == PINAnimatedImageStatusInfoProcessed is undefined.
 */
@property (nonatomic, readonly) size_t frameCount;
/**
 Any processing error that may have occured.
 */
@property (nonatomic, readonly) NSError *error;

/**
 The image at the frame index passed in.
 @param index The index of the frame to retrieve.
 @param cacheProvider An optional cache provider. Unneccesary to pass into this class.
 @warning Access to this property before status == PINAnimatedImageStatusInfoProcessed is undefined.
 */
- (CGImageRef)imageAtIndex:(NSUInteger)index cacheProvider:(id<PINCachedAnimatedFrameProvider>)cacheProvider;
/**
 The duration of the frame of the passed in index.
 @param index The index of the frame to retrieve the duration it should be shown for.
 @warning Access to this property before status == PINAnimatedImageStatusInfoProcessed is undefined.
 */
- (CFTimeInterval)durationAtIndex:(NSUInteger)index;
/**
 Clears out the strong references to any memory maps that are being held.
 */
- (void)clearAnimatedImageCache;

@end
