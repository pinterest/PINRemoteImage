//
//  PINAnimatedImageManager.m
//  Pods
//
//  Created by Garrett Moon on 4/5/16.
//
//

#import "PINAnimatedImageManager.h"

#import <ImageIO/ImageIO.h>
#if PIN_TARGET_IOS
#import <MobileCoreServices/UTCoreTypes.h>
#elif PIN_TARGET_MAC
#import <CoreServices/CoreServices.h>
#endif

#import "PINRemoteLock.h"

static const NSUInteger maxFileSize = 50000000; //max file size in bytes
static const Float32 maxFileDuration = 1; //max duration of a file in seconds

typedef void(^PINAnimatedImageInfoProcessed)(PINImage *coverImage, Float32 *durations, CFTimeInterval totalDuration, size_t loopCount, size_t frameCount, size_t width, size_t height, UInt32 bitmapInfo);

BOOL PINStatusCoverImageCompleted(PINAnimatedImageStatus status);
BOOL PINStatusCoverImageCompleted(PINAnimatedImageStatus status) {
  return status == PINAnimatedImageStatusInfoProcessed || status == PINAnimatedImageStatusFirstFileProcessed || status == PINAnimatedImageStatusProcessed;
}

@interface PINAnimatedImageManager ()
{
  PINRemoteLock *_lock;
}

+ (instancetype)sharedManager;

@property (nonatomic, strong, readonly) NSString *temporaryDirectory;
@property (nonatomic, strong, readonly) NSMutableDictionary <NSData *, PINSharedAnimatedImage *> *animatedImages;
@property (nonatomic, strong, readonly) dispatch_queue_t serialProcessingQueue;

@end

@implementation PINAnimatedImageManager

+ (instancetype)sharedManager
{
  static dispatch_once_t onceToken;
  static PINAnimatedImageManager *sharedManager;
  dispatch_once(&onceToken, ^{
    sharedManager = [[PINAnimatedImageManager alloc] init];
  });
  return sharedManager;
}

- (instancetype)init
{
  if (self = [super init]) {
    //On iOS temp directories are not shared between apps. This may not be safe on OS X or other systems
    _temporaryDirectory = [NSTemporaryDirectory() stringByAppendingPathComponent:@"PINAnimatedImageCache"];
    [self cleanupFiles];
    
    _lock = [[PINRemoteLock alloc] initWithName:@"PINAnimatedImageManager lock"];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:_temporaryDirectory] == NO) {
      [[NSFileManager defaultManager] createDirectoryAtPath:_temporaryDirectory withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    _animatedImages = [[NSMutableDictionary alloc] init];
    _serialProcessingQueue = dispatch_queue_create("Serial animated image processing queue.", DISPATCH_QUEUE_SERIAL);
    
    __weak PINAnimatedImageManager *weakSelf = self;
#if PIN_TARGET_IOS
    NSString * const notificationName = UIApplicationWillTerminateNotification;
#elif PIN_TARGET_MAC
    NSString * const notificationName = NSApplicationWillTerminateNotification;
#endif
    [[NSNotificationCenter defaultCenter] addObserverForName:notificationName
                                                      object:nil
                                                       queue:nil
                                                  usingBlock:^(NSNotification * _Nonnull note) {
                                                    [weakSelf cleanupFiles];
                                                  }];
  }
  return self;
}

- (void)cleanupFiles
{
  [[NSFileManager defaultManager] removeItemAtPath:self.temporaryDirectory error:nil];
}

- (void)animatedPathForImageData:(NSData *)animatedImageData infoCompletion:(PINAnimatedImageSharedReady)infoCompletion completion:(PINAnimatedImageDecodedPath)completion
{
  __block BOOL startProcessing = NO;
  {
    [_lock lockWithBlock:^{
      PINSharedAnimatedImage *shared = self.animatedImages[animatedImageData];
      if (shared == nil) {
        shared = [[PINSharedAnimatedImage alloc] init];
        self.animatedImages[animatedImageData] = shared;
        startProcessing = YES;
      }
      
      if (shared.status == PINAnimatedImageStatusProcessed) {
        if (completion) {
          completion(YES, nil, nil);
        }
      } else if (shared.error) {
        if (completion) {
          completion(NO, nil, shared.error);
        }
      } else {
        if (completion) {
          shared.completions = [shared.completions arrayByAddingObject:completion];
        }
      }
      
      if (PINStatusCoverImageCompleted(shared.status)) {
        if (infoCompletion) {
          infoCompletion(shared.coverImage, shared);
        }
      } else {
        if (infoCompletion) {
          shared.infoCompletions = [shared.infoCompletions arrayByAddingObject:infoCompletion];
        }
      }
    }];
  }
  
  if (startProcessing) {
    dispatch_async(self.serialProcessingQueue, ^{
      [[self class] processAnimatedImage:animatedImageData temporaryDirectory:self.temporaryDirectory infoCompletion:^(PINImage *coverImage, Float32 *durations, CFTimeInterval totalDuration, size_t loopCount, size_t frameCount, size_t width, size_t height, UInt32 bitmapInfo) {
        __block NSArray *infoCompletions = nil;
        __block PINSharedAnimatedImage *shared = nil;
        [_lock lockWithBlock:^{
          shared = self.animatedImages[animatedImageData];
          [shared setInfoProcessedWithCoverImage:coverImage durations:durations totalDuration:totalDuration loopCount:loopCount frameCount:frameCount width:width height:height bitmapInfo:bitmapInfo];
          infoCompletions = shared.infoCompletions;
          shared.infoCompletions = @[];
        }];
        
        for (PINAnimatedImageSharedReady infoCompletion in infoCompletions) {
          infoCompletion(coverImage, shared);
        }
      } decodedPath:^(BOOL finished, NSString *path, NSError *error) {
        __block NSArray *completions = nil;
        {
          [_lock lockWithBlock:^{
            PINSharedAnimatedImage *shared = self.animatedImages[animatedImageData];
            
            if (path && error == nil) {
              shared.maps = [shared.maps arrayByAddingObject:[[PINSharedAnimatedImageFile alloc] initWithPath:path]];
            }
            shared.error = error;
            
            completions = shared.completions;
            if (finished || error) {
              shared.completions = @[];
            }
            
            if (finished) {
              shared.status = PINAnimatedImageStatusProcessed;
            } else {
              shared.status = PINAnimatedImageStatusFirstFileProcessed;
            }
          }];
        }
        
        for (PINAnimatedImageDecodedPath completion in completions) {
          completion(finished, path, error);
        }
      }];
    });
  }
}

+ (void)processAnimatedImage:(NSData *)animatedImageData
          temporaryDirectory:(NSString *)temporaryDirectory
              infoCompletion:(PINAnimatedImageInfoProcessed)infoCompletion
                 decodedPath:(PINAnimatedImageDecodedPath)completion
{
  NSUUID *UUID = [NSUUID UUID];
  NSError *error = nil;
  NSString *filePath = nil;
  //TODO Must handle file handle errors! Documentation says it throws exceptions on any errors :(
  NSFileHandle *fileHandle = [self fileHandle:&error filePath:&filePath temporaryDirectory:temporaryDirectory UUID:UUID count:0];
  UInt32 width;
  UInt32 height;
  UInt32 bitmapInfo;
  NSUInteger fileCount = 0;
  UInt32 frameCountForFile = 0;
  
#if PINAnimatedImageDebug
  CFTimeInterval start = CACurrentMediaTime();
#endif
  
  if (fileHandle && error == nil) {
    dispatch_queue_t diskWriteQueue = dispatch_queue_create("PINAnimatedImage disk write queue", DISPATCH_QUEUE_SERIAL);
    dispatch_group_t diskGroup = dispatch_group_create();
    
    CGImageSourceRef imageSource = CGImageSourceCreateWithData((CFDataRef)animatedImageData,
                                                               (CFDictionaryRef)@{(__bridge NSString *)kCGImageSourceTypeIdentifierHint : (__bridge NSString *)kUTTypeGIF,
                                                                                  (__bridge NSString *)kCGImageSourceShouldCache : (__bridge NSNumber *)kCFBooleanFalse});
    
    if (imageSource) {
      UInt32 frameCount = (UInt32)CGImageSourceGetCount(imageSource);
      NSDictionary *imageProperties = (__bridge_transfer NSDictionary *)CGImageSourceCopyProperties(imageSource, nil);
      UInt32 loopCount = (UInt32)[[[imageProperties objectForKey:(__bridge NSString *)kCGImagePropertyGIFDictionary]
                                   objectForKey:(__bridge NSString *)kCGImagePropertyGIFLoopCount] unsignedLongValue];
      
      Float32 fileDuration = 0;
      NSUInteger fileSize = 0;
      Float32 durations[frameCount];
      CFTimeInterval totalDuration = 0;
      PINImage *coverImage = nil;
      
      //Gather header file info
      for (NSUInteger frameIdx = 0; frameIdx < frameCount; frameIdx++) {
        if (frameIdx == 0) {
          CGImageRef frameImage = CGImageSourceCreateImageAtIndex(imageSource, frameIdx, (CFDictionaryRef)@{(__bridge NSString *)kCGImageSourceShouldCache : (__bridge NSNumber *)kCFBooleanFalse});
          if (frameImage == nil) {
            error = [NSError errorWithDomain:kPINAnimatedImageErrorDomain code:PINAnimatedImageErrorImageFrameError userInfo:nil];
            break;
          }
          
          bitmapInfo = CGImageGetBitmapInfo(frameImage);
          
          width = (UInt32)CGImageGetWidth(frameImage);
          height = (UInt32)CGImageGetHeight(frameImage);
          
#if PIN_TARGET_IOS
          coverImage = [UIImage imageWithCGImage:frameImage];
#elif PIN_TARGET_MAC
          coverImage = [[NSImage alloc] initWithCGImage:frameImage size:CGSizeMake(width, height)];
#endif
          CGImageRelease(frameImage);
        }
        
        Float32 duration = [[self class] frameDurationAtIndex:frameIdx source:imageSource];
        durations[frameIdx] = duration;
        totalDuration += duration;
      }
      
      if (error == nil) {
        //Get size, write file header get coverImage
        
        //blockDurations will be freed below after calling infoCompletion
        Float32 *blockDurations = (Float32 *)malloc(sizeof(Float32) * frameCount);
        memcpy(blockDurations, durations, sizeof(Float32) * frameCount);
        
        dispatch_group_async(diskGroup, diskWriteQueue, ^{
          [self writeFileHeader:fileHandle width:width height:height loopCount:loopCount frameCount:frameCount bitmapInfo:bitmapInfo durations:blockDurations];
          [fileHandle closeFile];
        });
        fileCount = 1;
        fileHandle = [self fileHandle:&error filePath:&filePath temporaryDirectory:temporaryDirectory UUID:UUID count:fileCount];
        
        dispatch_group_async(diskGroup, diskWriteQueue, ^{
          PINLog(@"notifying info");
          infoCompletion(coverImage, blockDurations, totalDuration, loopCount, frameCount, width, height, bitmapInfo);
          free(blockDurations);
          
          //write empty frame count
          [fileHandle writeData:[NSData dataWithBytes:&frameCountForFile length:sizeof(frameCountForFile)]];
        });
        
        //Process frames
        for (NSUInteger frameIdx = 0; frameIdx < frameCount; frameIdx++) {
          @autoreleasepool {
            if (fileDuration > maxFileDuration || fileSize > maxFileSize) {
              //create a new file
              dispatch_group_async(diskGroup, diskWriteQueue, ^{
                //prepend file with frameCount
                [fileHandle seekToFileOffset:0];
                [fileHandle writeData:[NSData dataWithBytes:&frameCountForFile length:sizeof(frameCountForFile)]];
                [fileHandle closeFile];
              });
              
              dispatch_group_async(diskGroup, diskWriteQueue, ^{
                PINLog(@"notifying file: %@", filePath);
                completion(NO, filePath, error);
              });
              
              diskGroup = dispatch_group_create();
              fileCount++;
              fileHandle = [self fileHandle:&error filePath:&filePath temporaryDirectory:temporaryDirectory UUID:UUID count:fileCount];
              frameCountForFile = 0;
              fileDuration = 0;
              fileSize = 0;
              //write empty frame count
              dispatch_group_async(diskGroup, diskWriteQueue, ^{
                [fileHandle writeData:[NSData dataWithBytes:&frameCountForFile length:sizeof(frameCountForFile)]];
              });
            }
            
            CGImageRef frameImage = CGImageSourceCreateImageAtIndex(imageSource, frameIdx, (CFDictionaryRef)@{(__bridge NSString *)kCGImageSourceShouldCache : (__bridge NSNumber *)kCFBooleanFalse});
            if (frameImage == nil) {
              error = [NSError errorWithDomain:kPINAnimatedImageErrorDomain code:PINAnimatedImageErrorImageFrameError userInfo:nil];
              break;
            }
            
            Float32 duration = durations[frameIdx];
            fileDuration += duration;
            NSData *frameData = (__bridge_transfer NSData *)CGDataProviderCopyData(CGImageGetDataProvider(frameImage));
            NSAssert(frameData.length == width * height * kPINAnimatedImageComponentsPerPixel, @"data should be width * height * 4 bytes");
            dispatch_group_async(diskGroup, diskWriteQueue, ^{
              [self writeFrameToFile:fileHandle duration:duration frameData:frameData];
            });
            
            CGImageRelease(frameImage);
            frameCountForFile++;
          }
        }
      }
      
      CFRelease(imageSource);
    }
    
    dispatch_group_wait(diskGroup, DISPATCH_TIME_FOREVER);
    
    //close the file handle
    PINLog(@"closing last file: %@", fileHandle);
    [fileHandle seekToFileOffset:0];
    [fileHandle writeData:[NSData dataWithBytes:&frameCountForFile length:sizeof(frameCountForFile)]];
    [fileHandle closeFile];
  }
  
#if PINAnimatedImageDebug
  CFTimeInterval interval = CACurrentMediaTime() - start;
  NSLog(@"Encoding and write time: %f", interval);
#endif
  
  completion(YES, filePath, error);
}

//http://stackoverflow.com/questions/16964366/delaytime-or-unclampeddelaytime-for-gifs
+ (Float32)frameDurationAtIndex:(NSUInteger)index source:(CGImageSourceRef)source
{
  Float32 frameDuration = kPINAnimatedImageDefaultDuration;
  NSDictionary *frameProperties = (__bridge_transfer NSDictionary *)CGImageSourceCopyPropertiesAtIndex(source, index, nil);
  // use unclamped delay time before delay time before default
  NSNumber *unclamedDelayTime = frameProperties[(__bridge NSString *)kCGImagePropertyGIFDictionary][(__bridge NSString *)kCGImagePropertyGIFUnclampedDelayTime];
  if (unclamedDelayTime) {
    frameDuration = [unclamedDelayTime floatValue];
  } else {
    NSNumber *delayTime = frameProperties[(__bridge NSString *)kCGImagePropertyGIFDictionary][(__bridge NSString *)kCGImagePropertyGIFDelayTime];
    if (delayTime) {
      frameDuration = [delayTime floatValue];
    }
  }
  
  if (frameDuration < kPINAnimatedImageMinimumDuration) {
    frameDuration = kPINAnimatedImageDefaultDuration;
  }
  
  return frameDuration;
}

+ (NSString *)filePathWithTemporaryDirectory:(NSString *)temporaryDirectory UUID:(NSUUID *)UUID count:(NSUInteger)count
{
  NSString *filePath = [temporaryDirectory stringByAppendingPathComponent:[UUID UUIDString]];
  if (count > 0) {
    filePath = [filePath stringByAppendingString:[@(count) stringValue]];
  }
  return filePath;
}

+ (NSFileHandle *)fileHandle:(NSError **)error filePath:(NSString **)filePath temporaryDirectory:(NSString *)temporaryDirectory UUID:(NSUUID *)UUID count:(NSUInteger)count;
{
  NSString *outFilePath = [self filePathWithTemporaryDirectory:temporaryDirectory UUID:UUID count:count];
  NSError *outError = nil;
  NSFileHandle *fileHandle = nil;
  
  if (outError == nil) {
    BOOL success = [[NSFileManager defaultManager] createFileAtPath:outFilePath contents:nil attributes:nil];
    if (success == NO) {
      outError = [NSError errorWithDomain:kPINAnimatedImageErrorDomain code:PINAnimatedImageErrorFileCreationError userInfo:nil];
    }
  }
  
  if (outError == nil) {
    fileHandle = [NSFileHandle fileHandleForWritingAtPath:outFilePath];
    if (fileHandle == nil) {
      outError = [NSError errorWithDomain:kPINAnimatedImageErrorDomain code:PINAnimatedImageErrorFileHandleError userInfo:nil];
    }
  }
  
  if (error) {
    *error = outError;
  }
  
  if (filePath) {
    *filePath = outFilePath;
  }
  
  return fileHandle;
}

/**
 PINAnimatedImage file header
 
 Header:
 [version] 2 bytes
 [width] 4 bytes
 [height] 4 bytes
 [loop count] 4 bytes
 [frame count] 4 bytes
 [bitmap info] 4 bytes
 [durations] 4 bytes * frame count
 
 */

+ (void)writeFileHeader:(NSFileHandle *)fileHandle width:(UInt32)width height:(UInt32)height loopCount:(UInt32)loopCount frameCount:(UInt32)frameCount bitmapInfo:(UInt32)bitmapInfo durations:(Float32*)durations
{
  UInt16 version = 1;
  [fileHandle writeData:[NSData dataWithBytes:&version length:sizeof(version)]];
  [fileHandle writeData:[NSData dataWithBytes:&width length:sizeof(width)]];
  [fileHandle writeData:[NSData dataWithBytes:&height length:sizeof(height)]];
  [fileHandle writeData:[NSData dataWithBytes:&loopCount length:sizeof(loopCount)]];
  [fileHandle writeData:[NSData dataWithBytes:&frameCount length:sizeof(frameCount)]];
  [fileHandle writeData:[NSData dataWithBytes:&bitmapInfo length:sizeof(bitmapInfo)]];
  [fileHandle writeData:[NSData dataWithBytes:durations length:sizeof(Float32) * frameCount]];
}

/**
 PINAnimatedImage frame file
 [frame count(in file)] 4 bytes
 [frame(s)]
 
 Each frame:
 [duration] 4 bytes
 [frame data] width * height * 4 bytes
 */

+ (void)writeFrameToFile:(NSFileHandle *)fileHandle duration:(Float32)duration frameData:(NSData *)frameData
{
  [fileHandle writeData:[NSData dataWithBytes:&duration length:sizeof(duration)]];
  [fileHandle writeData:frameData];
}

@end
