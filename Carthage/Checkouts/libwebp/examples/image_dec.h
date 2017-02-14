// Copyright 2016 Google Inc. All Rights Reserved.
//
// Use of this source code is governed by a BSD-style license
// that can be found in the COPYING file in the root of the source
// tree. An additional intellectual property rights grant can be found
// in the file PATENTS. All contributing project authors may
// be found in the AUTHORS file in the root of the source tree.
// -----------------------------------------------------------------------------
//
//  All-in-one library to decode PNG/JPEG/WebP/TIFF/WIC input images.
//
// Author: Skal (pascal.massimino@gmail.com)

#ifndef WEBP_EXAMPLES_IMAGE_DEC_H_
#define WEBP_EXAMPLES_IMAGE_DEC_H_

#include "webp/types.h"

#ifdef HAVE_CONFIG_H
#include "webp/config.h"
#endif

#include "./metadata.h"
#include "./jpegdec.h"
#include "./pngdec.h"
#include "./tiffdec.h"
#include "./webpdec.h"
#include "./wicdec.h"

#ifdef __cplusplus
extern "C" {
#endif

typedef enum {
  WEBP_PNG_FORMAT = 0,
  WEBP_JPEG_FORMAT,
  WEBP_TIFF_FORMAT,
  WEBP_WEBP_FORMAT,
  WEBP_UNSUPPORTED_FORMAT
} WebPInputFileFormat;

// Try to infer the image format. 'data_size' should be larger than 12.
// Returns WEBP_UNSUPPORTED_FORMAT if format can't be guess safely.
WebPInputFileFormat WebPGuessImageType(const uint8_t* const data,
                                       size_t data_size);

// Signature for common image-reading functions (ReadPNG, ReadJPEG, ...)
typedef int (*WebPImageReader)(const uint8_t* const data, size_t data_size,
                               struct WebPPicture* const pic,
                               int keep_alpha, struct Metadata* const metadata);

// This function is similar to WebPGuessImageType(), but returns a
// suitable reader function. Or NULL if the image can't be guessed.
WebPImageReader WebPGuessImageReader(const uint8_t* const data,
                                     size_t data_size);

#ifdef __cplusplus
}    // extern "C"
#endif

#endif  // WEBP_EXAMPLES_IMAGE_DEC_H_
