//
//  UIImage+WebP.m
//  Pods
//
//  Created by Garrett Moon on 11/18/14.
//
//

#import "PINImage+WebP.h"

#ifdef PIN_WEBP
#import "webp/decode.h"
#import "webp/encode.h"

static void releaseData(void *info, const void *data, size_t size)
{
    free((void *)data);
}

@implementation PINImage (PINWebP)

+ (PINImage *)pin_imageWithWebPData:(NSData *)webPData
{
    WebPBitstreamFeatures features;
    if (WebPGetFeatures([webPData bytes], [webPData length], &features) == VP8_STATUS_OK) {
        // Decode the WebP image data into a RGBA value array
        int height, width;
        uint8_t *data = NULL;
        int pixelLength = 0;
        
        if (features.has_alpha) {
            data = WebPDecodeRGBA([webPData bytes], [webPData length], &width, &height);
            pixelLength = 4;
        } else {
            data = WebPDecodeRGB([webPData bytes], [webPData length], &width, &height);
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
            
            return image;
        }
    }
    return nil;
}

+ (NSData *)pin_DataFromWebPimage:(PINImage *)image
{
    // convert color space.
    CGRect imageRect = CGRectMake(0, 0, image.size.width, image.size.height);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    NSUInteger bytesPerPixel = 4;
    NSUInteger bytesPerRow = bytesPerPixel * image.size.width;
    NSUInteger bitsPerComponent = 8;
    NSUInteger bitmapByteCount = bytesPerRow * image.size.height;
    
    unsigned char *rawData = (unsigned char*) calloc(bitmapByteCount, sizeof(unsigned char));

    CGContextRef context = CGBitmapContextCreate(rawData, image.size.width, image.size.height,
                                                 bitsPerComponent, bytesPerRow, colorSpace,
                                                 kCGImageAlphaPremultipliedLast | kCGImageByteOrder32Big);

    CGImageRef imageRef;
    #if PIN_TARGET_IOS
    CGContextDrawImage(context, imageRect, image.CGImage);
    imageRef = CGBitmapContextCreateImage(context);
    #elif PIN_TARGET_MAC
    NSGraphicsContext *graphicsContext = [NSGraphicsContext graphicsContextWithCGContext:context flipped:NO];
    imageRef = [image CGImageForProposedRect:&imageRect context:graphicsContext hints:nil];
    #endif
    
    CGColorSpaceRelease(colorSpace);
    CGContextRelease(context);
    
    CGDataProviderRef dataProvider = CGImageGetDataProvider(imageRef);
    CFDataRef dataRef = CGDataProviderCopyData(dataProvider);
    
    WebPConfig config;
    WebPConfigPreset(&config, WEBP_PRESET_DEFAULT, 75);
    
    WebPPicture picture;
    WebPPictureInit(&picture);
    
    picture.colorspace = WEBP_YUV420A;
    picture.width = image.size.width;
    picture.height = image.size.height;
    
    WebPPictureImportRGBA(&picture, (uint8_t *)CFDataGetBytePtr(dataRef), (int) CGImageGetBytesPerRow(imageRef));
    WebPCleanupTransparentArea(&picture);
    
    CFRelease(dataRef);
    
    WebPMemoryWriter writer;
    WebPMemoryWriterInit(&writer);
    
    picture.writer = WebPMemoryWrite;
    picture.custom_ptr = &writer;
    
    WebPEncode(&config, &picture);
    
    NSData *data = [NSData dataWithBytes:writer.mem length:writer.size];
    
    WebPPictureFree(&picture);
    free(rawData);
    
    return data;
    
}

@end

#endif
