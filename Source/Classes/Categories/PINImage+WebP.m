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

@implementation PINImage (PINWebP)

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

#if PIN_TARGET_IOS
#define PIN_WEBP_DECODE_CLEANUP() UIGraphicsEndImageContext()
#elif PIN_TARGET_MAC
#define PIN_WEBP_DECODE_CLEANUP() [image unlockFocus]
#endif

// We let the system decide all the bitmap options for us, so Core Animation won't have
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
    CGContextRef ctx = NULL;
    PINImage *image;
#if PIN_TARGET_IOS
    UIGraphicsBeginImageContextWithOptions(size, !cfg.input.has_alpha, 1.0);
    ctx = UIGraphicsGetCurrentContext();
#elif PIN_TARGET_MAC
    image = [[NSImage alloc] initWithSize:NSSizeFromCGSize(size)];
    [image lockFocus];
    ctx = NSGraphicsContext.currentContext.CGContext;
#endif
    NSAssert(ctx != NULL, @"Failed to get CG context.");
    BOOL getColorspaceFailed = NO;
    cfg.output.colorspace = webp_cs_mode_from_cg_bitmap_info(CGBitmapContextGetBitmapInfo(ctx),
                                                             &getColorspaceFailed);
    if (getColorspaceFailed) {
        PIN_WEBP_DECODE_CLEANUP();
        return nil;
    }
    cfg.output.width = cfg.input.width;
    cfg.output.height = cfg.input.height;
    cfg.output.is_external_memory = 1;
    cfg.output.u.RGBA.rgba = (uint8_t *)CGBitmapContextGetData(ctx);
    cfg.output.u.RGBA.stride = (int)CGBitmapContextGetBytesPerRow(ctx);
    cfg.output.u.RGBA.size = cfg.output.u.RGBA.stride * cfg.input.height;
    int status = WebPDecode(webPData.bytes, webPData.length, &cfg);
#if PIN_TARGET_IOS
    if (status == VP8_STATUS_OK) {
        image = UIGraphicsGetImageFromCurrentImageContext();
    }
#endif
    PIN_WEBP_DECODE_CLEANUP();
    return status == VP8_STATUS_OK ? image : nil;
}

@end

#endif
