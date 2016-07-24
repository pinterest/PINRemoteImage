//
//  PINProgressiveImage+Accelerate.m
//  PINRemoteImage
//
//  Created by Adlai Holler on 5/23/16.
//  Copyright © 2016 Garrett Moon. All rights reserved.
//

#import "PINProgressiveImage+Accelerate.h"
#import <ImageIO/ImageIO.h>
#import <Accelerate/Accelerate.h>

#import "PINRemoteImage.h"
#import "PINImage+DecodedImage.h"

@implementation PINProgressiveImage (Accelerate)

//Heavily cribbed from https://developer.apple.com/library/ios/samplecode/UIImageEffects/Listings/UIImageEffects_UIImageEffects_m.html#//apple_ref/doc/uid/DTS40013396-UIImageEffects_UIImageEffects_m-DontLinkElementID_9
+ (PINImage *)postProcessImageUsingAccelerate:(PINImage *)inputImage withProgress:(float)progress
{
    PINImage *outputImage = nil;
    CGImageRef inputImageRef = CGImageRetain(inputImage.CGImage);
    if (inputImageRef == nil) {
        return nil;
    }

    CGSize inputSize = inputImage.size;
    if (inputSize.width < 1 ||
        inputSize.height < 1) {
        CGImageRelease(inputImageRef);
        return nil;
    }

#if PIN_TARGET_IOS
    CGFloat imageScale = inputImage.scale;
#elif PIN_TARGET_MAC
    // TODO: What scale factor should be used here?
    CGFloat imageScale = [[NSScreen mainScreen] backingScaleFactor];
#endif

    CGFloat radius = (inputImage.size.width / 25.0) * MAX(0, 1.0 - progress);
    radius *= imageScale;

    //we'll round the radius to a whole number below anyway,
    if (radius < FLT_EPSILON) {
        CGImageRelease(inputImageRef);
        return inputImage;
    }

    CGContextRef ctx;
#if PIN_TARGET_IOS
    UIGraphicsBeginImageContextWithOptions(inputSize, YES, imageScale);
    ctx = UIGraphicsGetCurrentContext();
#elif PIN_TARGET_MAC
    ctx = CGBitmapContextCreate(0, inputSize.width, inputSize.height, 8, 0, [NSColorSpace genericRGBColorSpace].CGColorSpace, kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrder32Little);
#endif

    if (ctx) {
#if PIN_TARGET_IOS
        CGContextScaleCTM(ctx, 1.0, -1.0);
        CGContextTranslateCTM(ctx, 0, -inputSize.height);
#endif

        vImage_Buffer effectInBuffer;
        vImage_Buffer scratchBuffer;

        vImage_Buffer *inputBuffer;
        vImage_Buffer *outputBuffer;

        vImage_CGImageFormat format = {
            .bitsPerComponent = 8,
            .bitsPerPixel = 32,
            .colorSpace = NULL,
            // (kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrder32Little)
            // requests a BGRA buffer.
            .bitmapInfo = kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrder32Little,
            .version = 0,
            .decode = NULL,
            .renderingIntent = kCGRenderingIntentDefault
        };

        vImage_Error e = vImageBuffer_InitWithCGImage(&effectInBuffer, &format, NULL, inputImage.CGImage, kvImagePrintDiagnosticsToConsole);
        if (e == kvImageNoError)
        {
            e = vImageBuffer_Init(&scratchBuffer, effectInBuffer.height, effectInBuffer.width, format.bitsPerPixel, kvImageNoFlags);
            if (e == kvImageNoError) {
                inputBuffer = &effectInBuffer;
                outputBuffer = &scratchBuffer;

                // A description of how to compute the box kernel width from the Gaussian
                // radius (aka standard deviation) appears in the SVG spec:
                // http://www.w3.org/TR/SVG/filters.html#feGaussianBlurElement
                //
                // For larger values of 's' (s >= 2.0), an approximation can be used: Three
                // successive box-blurs build a piece-wise quadratic convolution kernel, which
                // approximates the Gaussian kernel to within roughly 3%.
                //
                // let d = floor(s * 3*sqrt(2*pi)/4 + 0.5)
                //
                // ... if d is odd, use three box-blurs of size 'd', centered on the output pixel.
                //
                if (radius - 2. < __FLT_EPSILON__)
                    radius = 2.;
                uint32_t wholeRadius = floor((radius * 3. * sqrt(2 * M_PI) / 4 + 0.5) / 2);

                wholeRadius |= 1; // force wholeRadius to be odd so that the three box-blur methodology works.

                //calculate the size necessary for vImageBoxConvolve_ARGB8888, this does not actually do any operations.
                NSInteger tempBufferSize = vImageBoxConvolve_ARGB8888(inputBuffer, outputBuffer, NULL, 0, 0, wholeRadius, wholeRadius, NULL, kvImageGetTempBufferSize | kvImageEdgeExtend);
                void *tempBuffer = malloc(tempBufferSize);

                if (tempBuffer) {
                    //errors can be ignored because we've passed in allocated memory
                    vImageBoxConvolve_ARGB8888(inputBuffer, outputBuffer, tempBuffer, 0, 0, wholeRadius, wholeRadius, NULL, kvImageEdgeExtend);
                    vImageBoxConvolve_ARGB8888(outputBuffer, inputBuffer, tempBuffer, 0, 0, wholeRadius, wholeRadius, NULL, kvImageEdgeExtend);
                    vImageBoxConvolve_ARGB8888(inputBuffer, outputBuffer, tempBuffer, 0, 0, wholeRadius, wholeRadius, NULL, kvImageEdgeExtend);

                    free(tempBuffer);

                    //switch input and output
                    vImage_Buffer *temp = inputBuffer;
                    inputBuffer = outputBuffer;
                    outputBuffer = temp;

                    CGImageRef effectCGImage = vImageCreateCGImageFromBuffer(inputBuffer, &format, &cleanupBuffer, NULL, kvImageNoAllocate, NULL);
                    if (effectCGImage == NULL) {
                        //if creating the cgimage failed, the cleanup buffer on input buffer will not be called, we must dealloc ourselves
                        free(inputBuffer->data);
                    } else {
                        // draw effect image
                        CGContextSaveGState(ctx);
                        CGContextDrawImage(ctx, CGRectMake(0, 0, inputSize.width, inputSize.height), effectCGImage);
                        CGContextRestoreGState(ctx);
                        CGImageRelease(effectCGImage);
                    }

                    // Cleanup
                    free(outputBuffer->data);
#if PIN_TARGET_IOS
                    outputImage = UIGraphicsGetImageFromCurrentImageContext();
#elif PIN_TARGET_MAC
                    CGImageRef outputImageRef = CGBitmapContextCreateImage(ctx);
                    outputImage = [[NSImage alloc] initWithCGImage:outputImageRef size:inputSize];
                    CFRelease(outputImageRef);
#endif

                }
            } else {
                if (scratchBuffer.data) {
                    free(scratchBuffer.data);
                }
                free(effectInBuffer.data);
            }
        } else {
            if (effectInBuffer.data) {
                free(effectInBuffer.data);
            }
        }
    }

#if PIN_TARGET_IOS
    UIGraphicsEndImageContext();
#endif

    CGImageRelease(inputImageRef);

    return outputImage;
}

//  Helper function to handle deferred cleanup of a buffer.
static void cleanupBuffer(void *userData, void *buf_data)
{
    free(buf_data);
}

@end
