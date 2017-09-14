// Copyright 2014 Google Inc. All Rights Reserved.
//
// Use of this source code is governed by a BSD-style license
// that can be found in the COPYING file in the root of the source
// tree. An additional intellectual property rights grant can be found
// in the file PATENTS. All contributing project authors may
// be found in the AUTHORS file in the root of the source tree.
// -----------------------------------------------------------------------------
//
// WebP decode.

#include "./webpdec.h"

#include <stdio.h>
#include <stdlib.h>

#include "webp/decode.h"
#include "webp/encode.h"
#include "./imageio_util.h"
#include "./metadata.h"

//------------------------------------------------------------------------------
// WebP decoding

static const char* const kStatusMessages[VP8_STATUS_NOT_ENOUGH_DATA + 1] = {
  "OK", "OUT_OF_MEMORY", "INVALID_PARAM", "BITSTREAM_ERROR",
  "UNSUPPORTED_FEATURE", "SUSPENDED", "USER_ABORT", "NOT_ENOUGH_DATA"
};

static void PrintAnimationWarning(const WebPDecoderConfig* const config) {
  if (config->input.has_animation) {
    fprintf(stderr,
            "Error! Decoding of an animated WebP file is not supported.\n"
            "       Use webpmux to extract the individual frames or\n"
            "       vwebp to view this image.\n");
  }
}

void PrintWebPError(const char* const in_file, int status) {
  fprintf(stderr, "Decoding of %s failed.\n", in_file);
  fprintf(stderr, "Status: %d", status);
  if (status >= VP8_STATUS_OK && status <= VP8_STATUS_NOT_ENOUGH_DATA) {
    fprintf(stderr, "(%s)", kStatusMessages[status]);
  }
  fprintf(stderr, "\n");
}

int LoadWebP(const char* const in_file,
             const uint8_t** data, size_t* data_size,
             WebPBitstreamFeatures* bitstream) {
  VP8StatusCode status;
  WebPBitstreamFeatures local_features;
  if (!ImgIoUtilReadFile(in_file, data, data_size)) return 0;

  if (bitstream == NULL) {
    bitstream = &local_features;
  }

  status = WebPGetFeatures(*data, *data_size, bitstream);
  if (status != VP8_STATUS_OK) {
    free((void*)*data);
    *data = NULL;
    *data_size = 0;
    PrintWebPError(in_file, status);
    return 0;
  }
  return 1;
}

//------------------------------------------------------------------------------

VP8StatusCode DecodeWebP(const uint8_t* const data, size_t data_size,
                         WebPDecoderConfig* const config) {
  if (config == NULL) return VP8_STATUS_INVALID_PARAM;
  PrintAnimationWarning(config);
  return WebPDecode(data, data_size, config);
}

VP8StatusCode DecodeWebPIncremental(
    const uint8_t* const data, size_t data_size,
    WebPDecoderConfig* const config) {
  VP8StatusCode status = VP8_STATUS_OK;
  if (config == NULL) return VP8_STATUS_INVALID_PARAM;

  PrintAnimationWarning(config);

  // Decoding call.
  {
    WebPIDecoder* const idec = WebPIDecode(data, data_size, config);
    if (idec == NULL) {
      fprintf(stderr, "Failed during WebPINewDecoder().\n");
      return VP8_STATUS_OUT_OF_MEMORY;
    } else {
#ifdef WEBP_EXPERIMENTAL_FEATURES
      size_t size = 0;
      const size_t incr = 2 + (data_size / 20);
      while (size < data_size) {
        size_t next_size = size + (rand() % incr);
        if (next_size > data_size) next_size = data_size;
        status = WebPIUpdate(idec, data, next_size);
        if (status != VP8_STATUS_OK && status != VP8_STATUS_SUSPENDED) break;
        size = next_size;
      }
#else
      status = WebPIUpdate(idec, data, data_size);
#endif
      WebPIDelete(idec);
    }
  }
  return status;
}

// -----------------------------------------------------------------------------

int ReadWebP(const uint8_t* const data, size_t data_size,
             WebPPicture* const pic,
             int keep_alpha, Metadata* const metadata) {
  int ok = 0;
  VP8StatusCode status = VP8_STATUS_OK;
  WebPDecoderConfig config;
  WebPDecBuffer* const output_buffer = &config.output;
  WebPBitstreamFeatures* const bitstream = &config.input;

  if (data == NULL || data_size == 0 || pic == NULL) return 0;

  // TODO(jzern): add Exif/XMP/ICC extraction.
  if (metadata != NULL) {
    fprintf(stderr, "Warning: metadata extraction from WebP is unsupported.\n");
  }

  if (!WebPInitDecoderConfig(&config)) {
    fprintf(stderr, "Library version mismatch!\n");
    return 0;
  }

  status = WebPGetFeatures(data, data_size, bitstream);
  if (status != VP8_STATUS_OK) {
    PrintWebPError("input data", status);
    return 0;
  }
  {
    const int has_alpha = keep_alpha && bitstream->has_alpha;
    if (pic->use_argb) {
      output_buffer->colorspace = has_alpha ? MODE_RGBA : MODE_RGB;
    } else {
      output_buffer->colorspace = has_alpha ? MODE_YUVA : MODE_YUV;
    }

    status = DecodeWebP(data, data_size, &config);
    if (status == VP8_STATUS_OK) {
      pic->width = output_buffer->width;
      pic->height = output_buffer->height;
      if (pic->use_argb) {
        const uint8_t* const rgba = output_buffer->u.RGBA.rgba;
        const int stride = output_buffer->u.RGBA.stride;
        ok = has_alpha ? WebPPictureImportRGBA(pic, rgba, stride)
                       : WebPPictureImportRGB(pic, rgba, stride);
      } else {
        pic->colorspace = has_alpha ? WEBP_YUV420A : WEBP_YUV420;
        ok = WebPPictureAlloc(pic);
        if (!ok) {
          status = VP8_STATUS_OUT_OF_MEMORY;
        } else {
          const WebPYUVABuffer* const yuva = &output_buffer->u.YUVA;
          const int uv_width = (pic->width + 1) >> 1;
          const int uv_height = (pic->height + 1) >> 1;
          ImgIoUtilCopyPlane(yuva->y, yuva->y_stride,
                             pic->y, pic->y_stride, pic->width, pic->height);
          ImgIoUtilCopyPlane(yuva->u, yuva->u_stride,
                             pic->u, pic->uv_stride, uv_width, uv_height);
          ImgIoUtilCopyPlane(yuva->v, yuva->v_stride,
                             pic->v, pic->uv_stride, uv_width, uv_height);
          if (has_alpha) {
            ImgIoUtilCopyPlane(yuva->a, yuva->a_stride,
                               pic->a, pic->a_stride, pic->width, pic->height);
          }
        }
      }
    }
  }

  if (status != VP8_STATUS_OK) {
    PrintWebPError("input data", status);
  }

  WebPFreeDecBuffer(output_buffer);
  return ok;
}

// -----------------------------------------------------------------------------
