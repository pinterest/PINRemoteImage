//
//  PINAnimatedImageManager.h
//  Pods
//
//  Created by Garrett Moon on 4/5/16.
//
//

#import <Foundation/Foundation.h>

#import "PINAnimatedImage.h"

@class PINRemoteLock;
@class PINSharedAnimatedImage;
@class PINSharedAnimatedImageFile;

typedef void(^PINAnimatedImageSharedReady)(UIImage *coverImage, PINSharedAnimatedImage *shared);
typedef void(^PINAnimatedImageDecodedPath)(BOOL finished, NSString *path, NSError *error);

@interface PINAnimatedImageManager : NSObject

+ (instancetype)sharedManager;

- (void)animatedPathForImageData:(NSData *)animatedImageData infoCompletion:(PINAnimatedImageSharedReady)infoCompletion completion:(PINAnimatedImageDecodedPath)completion;

@end

@interface PINSharedAnimatedImage : NSObject
{
  PINRemoteLock *_coverImageLock;
}

//This is intentionally atomic. PINAnimatedImageManager must be able to add entries
//and clients must be able to read them concurrently.
@property (atomic, strong, readwrite) NSArray <PINSharedAnimatedImageFile *> *maps;

@property (nonatomic, strong, readwrite) NSArray <PINAnimatedImageDecodedPath> *completions;
@property (nonatomic, strong, readwrite) NSArray <PINAnimatedImageSharedReady> *infoCompletions;
@property (nonatomic, weak, readwrite) UIImage *coverImage;
@property (nonatomic, strong, readwrite) NSError *error;
//TODO is status thread safe?
@property (nonatomic, assign, readwrite) PINAnimatedImageStatus status;

- (void)setInfoProcessedWithCoverImage:(UIImage *)coverImage durations:(Float32 *)durations totalDuration:(CFTimeInterval)totalDuration loopCount:(size_t)loopCount frameCount:(size_t)frameCount width:(size_t)width height:(size_t)height bitmapInfo:(CGBitmapInfo)bitmapInfo;

@property (nonatomic, readonly) Float32 *durations;
@property (nonatomic, readonly) CFTimeInterval totalDuration;
@property (nonatomic, readonly) size_t loopCount;
@property (nonatomic, readonly) size_t frameCount;
@property (nonatomic, readonly) size_t width;
@property (nonatomic, readonly) size_t height;
@property (nonatomic, readonly) CGBitmapInfo bitmapInfo;

@end

@interface PINSharedAnimatedImageFile : NSObject
{
  PINRemoteLock *_lock;
}

@property (nonatomic, strong, readonly) NSString *path;
@property (nonatomic, assign, readonly) UInt32 frameCount;
@property (nonatomic, weak, readonly) NSData *memoryMappedData;

- (instancetype)initWithPath:(NSString *)path NS_DESIGNATED_INITIALIZER;

@end
