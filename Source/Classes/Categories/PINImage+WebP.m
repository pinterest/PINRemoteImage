//
//  UIImage+WebP.m
//  Pods
//
//  Created by Garrett Moon on 11/18/14.
//
//

#import "PINImage+WebP.h"

#if PIN_WEBP

#import "webp/decode.h"

static void releaseData(void *info, const void *data, size_t size)
{
    WebPFree((void *)data);
}

@implementation PINImage (PINWebP)

#if PIN_TARGET_IOS

static enum WEBP_CSP_MODE webp_cs_mode_from_cg_bitmap_info(CGBitmapInfo info, BOOL *fail) {
    CGImageByteOrderInfo byteOrder = info & kCGBitmapByteOrderMask;
    BOOL keepByteOrder;
    switch (byteOrder) {
        case kCGImageByteOrder32Big:
            keepByteOrder = YES;
            break;
        case kCGImageByteOrder32Little:
            keepByteOrder = NO;
            break;
        case kCGImageByteOrder16Big:
        case kCGImageByteOrder16Little:
        case kCGImageByteOrderDefault:
        case kCGImageByteOrderMask:
            *fail = YES;
            return MODE_RGBA;
    }

    CGImageAlphaInfo ai = info & kCGBitmapAlphaInfoMask;
    switch (ai) {
        case kCGImageAlphaLast:
        case kCGImageAlphaNoneSkipLast:
            return keepByteOrder ? MODE_RGBA : MODE_ARGB;
        case kCGImageAlphaNone:
            return keepByteOrder ? MODE_RGB  : MODE_BGR;
        case kCGImageAlphaFirst:
        case kCGImageAlphaNoneSkipFirst:
            return keepByteOrder ? MODE_ARGB : MODE_BGRA;
        case kCGImageAlphaPremultipliedLast:
            return keepByteOrder ? MODE_rgbA : MODE_Argb;
        case kCGImageAlphaPremultipliedFirst:
            return keepByteOrder ? MODE_Argb : MODE_rgbA;
        case kCGImageAlphaOnly:
            *fail = YES;
            return MODE_RGB;
    }
}

// For iOS we let the system decide all the bitmap options for us, so Core Animation won't have
// to copy our images over to the render server. Use "Color Copied Images" in the iOS simulator to
// detect this case.
+ (PINImage *)pin_imageWithWebPData:(NSData *)webPData
{
    WebPDecoderConfig cfg;
    WebPInitDecoderConfig(&cfg);
    if (WebPGetFeatures(webPData.bytes, webPData.length, &cfg.input) != VP8_STATUS_OK) {
        return nil;
    }
    CGSize size = CGSizeMake(cfg.input.width, cfg.input.height);
    UIGraphicsBeginImageContextWithOptions(size, !cfg.input.has_alpha, 1.0);
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    BOOL fail = NO;
    cfg.output.colorspace = webp_cs_mode_from_cg_bitmap_info(CGBitmapContextGetBitmapInfo(ctx),
                                                             &fail);
    if (fail) {
        UIGraphicsEndImageContext();
        return nil;
    }
    cfg.output.width = cfg.input.width;
    cfg.output.height = cfg.input.height;
    cfg.output.is_external_memory = 1;
    cfg.output.u.RGBA.rgba = (uint8_t *)CGBitmapContextGetData(ctx);
    cfg.output.u.RGBA.stride = (int)CGBitmapContextGetBytesPerRow(ctx);
    cfg.output.u.RGBA.size = cfg.output.u.RGBA.stride * cfg.input.height;
    int status = WebPDecode(webPData.bytes, webPData.length, &cfg);
    UIImage *image = nil;
    if (status == VP8_STATUS_OK) {
        image = UIGraphicsGetImageFromCurrentImageContext();
    }
    UIGraphicsEndImageContext();
    return image;
}

#elif PIN_TARGET_MAC

// TODO: Can we get the optimal bitmap config from macOS like we do for iOS?
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
            
            PINImage *image = [[self alloc] initWithCGImage:imageRef size:CGSizeZero];
            
            CGImageRelease(imageRef);
            CGColorSpaceRelease(colorSpaceRef);
            CGDataProviderRelease(provider);
            
            return image;
        }
    }
    return nil;
}

#endif

@end

#endif
