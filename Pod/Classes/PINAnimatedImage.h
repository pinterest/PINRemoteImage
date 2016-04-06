//
//  PINAnimatedImage.h
//  Pods
//
//  Created by Garrett Moon on 3/18/16.
//
//

#import <Foundation/Foundation.h>

#import "PINRemoteImageMacros.h"

#define PINAnimatedImageDebug  0

extern NSString *kPINAnimatedImageErrorDomain;

typedef NS_ENUM(NSUInteger, PINAnimatedImageError) {
  PINAnimatedImageErrorNoError = 0,
  PINAnimatedImageErrorFileCreationError,
  PINAnimatedImageErrorFileHandleError,
  PINAnimatedImageErrorImageFrameError,
  PINAnimatedImageErrorMappingError,
};

typedef NS_ENUM(NSUInteger, PINAnimatedImageStatus) {
  PINAnimatedImageStatusUnprocessed = 0,
  PINAnimatedImageStatusInfoProcessed,
  PINAnimatedImageStatusFirstFileProcessed,
  PINAnimatedImageStatusProcessed,
  PINAnimatedImageStatusCanceled,
  PINAnimatedImageStatusError,
};

extern const size_t kPINAnimatedImageComponentsPerPixel;
extern const Float32 kPINAnimatedImageDefaultDuration;
//http://nullsleep.tumblr.com/post/16524517190/animated-gif-minimum-frame-delay-browser
extern const Float32 kPINAnimatedImageMinimumDuration;
extern const NSTimeInterval kPINAnimatedImageDisplayRefreshRate;

typedef void(^PINAnimatedImageInfoReady)(PINImage *coverImage);

@interface PINAnimatedImage : NSObject

- (instancetype)initWithAnimatedImageData:(NSData *)animatedImageData NS_DESIGNATED_INITIALIZER;

@property (nonatomic, strong, readwrite) PINAnimatedImageInfoReady infoCompletion;
@property (nonatomic, strong, readwrite) dispatch_block_t fileReady;
@property (nonatomic, strong, readwrite) dispatch_block_t animatedImageReady;

@property (nonatomic, assign, readwrite) PINAnimatedImageStatus status;

//Access to any properties or methods below this line before status == PINAnimatedImageStatusInfoProcessed is undefined.
@property (nonatomic, readonly) PINImage *coverImage;
@property (nonatomic, readonly) BOOL coverImageReady;
@property (nonatomic, readonly) BOOL playbackReady;
@property (nonatomic, readonly) CFTimeInterval totalDuration;
@property (nonatomic, readonly) NSUInteger frameInterval;
@property (nonatomic, readonly) size_t loopCount;
@property (nonatomic, readonly) size_t frameCount;

- (CGImageRef)imageAtIndex:(NSUInteger)index;
- (CFTimeInterval)durationAtIndex:(NSUInteger)index;
- (void)clearAnimatedImageCache;

@end
