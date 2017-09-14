//
//  PINWebPAnimatedImage.m
//  PINRemoteImage
//
//  Created by Garrett Moon on 9/14/17.
//  Copyright © 2017 Pinterest. All rights reserved.
//

#if PIN_WEBP

#import "PINWebPAnimatedImage.h"

#import "NSData+ImageDetectors.h"

#import "demux.h"

@interface PINWebPAnimatedImage ()
{
    WebPData _underlyingData;
}

@end

static void releaseData(void *info, const void *data, size_t size)
{
    free((void *)data);
}

@implementation PINWebPAnimatedImage

- (instancetype)initWithAnimatedImageData:(NSData *)animatedImageData
{
    if (self = [super init]) {
        _underlyingData.bytes = [animatedImageData bytes];
        _underlyingData.size = [animatedImageData length];
        WebPDemuxer* demux = WebPDemux(&_underlyingData);
        
        uint32_t width = WebPDemuxGetI(demux, WEBP_FF_CANVAS_WIDTH);
        uint32_t height = WebPDemuxGetI(demux, WEBP_FF_CANVAS_HEIGHT);
        //        uint32_t flags = WebPDemuxGetI(demux, WEBP_FF_FORMAT_FLAGS);
        WebPBitstreamFeatures features;
        if (WebPGetFeatures(_underlyingData.bytes, _underlyingData.size, &features) == VP8_STATUS_OK) {
            // ... (Iterate over all frames).
            WebPIterator iter;
            if (WebPDemuxGetFrame(demux, 1, &iter)) {
                do {
                    // ... (Consume 'iter'; e.g. Decode 'iter.fragment' with WebPDecode(),
                    // ... and get other frame properties like width, height, offsets etc.
                    // ... see 'struct WebPIterator' below for more info).
                    uint8_t *data = NULL;
                    int pixelLength = 0;
                    
                    if (features.has_alpha) {
                        data = WebPDecodeRGBA(iter.fragment.bytes, iter.fragment.size, NULL, NULL);
                        pixelLength = 4;
                    } else {
                        data = WebPDecodeRGB(iter.fragment.bytes, iter.fragment.size, NULL, NULL);
                        pixelLength = 3;
                    }
                    
                    if (data) {
                        CGDataProviderRef provider = CGDataProviderCreateWithData(NULL, data, width * height * pixelLength, releaseData);
                        
                        CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
                        CGBitmapInfo bitmapInfo = kCGBitmapByteOrderDefault;
                        
                        if (features.has_alpha) {
                            bitmapInfo |= kCGImageAlphaLast;
                        } else {
                            bitmapInfo |= kCGImageAlphaNone;
                        }
                        
                        CGColorRenderingIntent renderingIntent = kCGRenderingIntentDefault;
                        CGImageRef imageRef = CGImageCreate(width,
                                                            height,
                                                            8,
                                                            8 * pixelLength,
                                                            pixelLength * width,
                                                            colorSpaceRef,
                                                            bitmapInfo,
                                                            provider,
                                                            NULL,
                                                            NO,
                                                            renderingIntent);
                        
                        PINImage *image = nil;
#if PIN_TARGET_IOS
                        image = [UIImage imageWithCGImage:imageRef];
#elif PIN_TARGET_MAC
                        image = [[self alloc] initWithCGImage:imageRef size:CGSizeZero];
#endif
                        
                        CGImageRelease(imageRef);
                        CGColorSpaceRelease(colorSpaceRef);
                        CGDataProviderRelease(provider);
                        
                        NSLog(@"image: ", image);
                    }
                    
                } while (WebPDemuxNextFrame(&iter));
                WebPDemuxReleaseIterator(&iter);
            }
        }
        
//        // ... (Extract metadata).
//        WebPChunkIterator chunk_iter;
//        if (flags & ICCP_FLAG) WebPDemuxGetChunk(demux, "ICCP", 1, &chunk_iter);
//        // ... (Consume the ICC profile in 'chunk_iter.chunk').
//        WebPDemuxReleaseChunkIterator(&chunk_iter);
//        if (flags & EXIF_FLAG) WebPDemuxGetChunk(demux, "EXIF", 1, &chunk_iter);
//        // ... (Consume the EXIF metadata in 'chunk_iter.chunk').
//        WebPDemuxReleaseChunkIterator(&chunk_iter);
//        if (flags & XMP_FLAG) WebPDemuxGetChunk(demux, "XMP ", 1, &chunk_iter);
//        // ... (Consume the XMP metadata in 'chunk_iter.chunk').
//        WebPDemuxReleaseChunkIterator(&chunk_iter);
        WebPDemuxDelete(demux);
    }
    return self;
}

- (BOOL)isDataSupported:(NSData *)data
{
    return [data pin_isWebP];
}

- (CFTimeInterval)durationAtIndex:(NSUInteger)index
{
    return 0;
}

- (CGImageRef)imageAtIndex:(NSUInteger)index
{
    return nil;
}

- (void)clearAnimatedImageCache
{
    
}

//
//@property (nonatomic, readwrite) void (^coverImageReadyCallback)(PINImage *coverImage);
//
///**
// @abstract Return the objects's cover image.
// */
//@property (nonatomic, readonly) PINImage *coverImage;
///**
// @abstract Return a boolean to indicate that the cover image is ready.
// */
//@property (nonatomic, readonly) BOOL coverImageReady;
///**
// @abstract Return the total duration of the animated image's playback.
// */
//@property (nonatomic, readonly) CFTimeInterval totalDuration;
///**
// @abstract Return the interval at which playback should occur. Will be set to a CADisplayLink's frame interval.
// */
//@property (nonatomic, readonly) NSUInteger frameInterval;
///**
// @abstract Return the total number of loops the animated image should play or 0 to loop infinitely.
// */
//@property (nonatomic, readonly) size_t loopCount;
///**
// @abstract Return the total number of frames in the animated image.
// */
//@property (nonatomic, readonly) size_t frameCount;
///**
// @abstract Return YES when playback is ready to occur.
// */
//@property (nonatomic, readonly) BOOL playbackReady;
///**
// @abstract Return any error that has occured. Playback will be paused if this returns non-nil.
// */
//@property (nonatomic, readonly) NSError *error;
///**
// @abstract Should be called when playback is ready.
// */
//@property (nonatomic, readwrite) dispatch_block_t playbackReadyCallback;
//
///**
// @abstract Return the image at a given index.
// */
//- (CGImageRef)imageAtIndex:(NSUInteger)index;
///**
// @abstract Return the duration at a given index.
// */
//- (CFTimeInterval)durationAtIndex:(NSUInteger)index;
///**
// @abstract Clear any cached data. Called when playback is paused.
// */
//- (void)clearAnimatedImageCache;

@end

#endif
