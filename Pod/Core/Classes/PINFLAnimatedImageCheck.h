//
//  PINFLAnimatedImageCheck.h
//  Pods
//
//  Created by Sam Dean on 30/09/2015.
//
//

#ifndef PINFLAnimatedImageCheck_h
#define PINFLAnimatedImageCheck_h

#if __has_include(<FLAnimatedImage/FLAnimatedImage.h>)
#define USE_FLANIMATED_IMAGE    1
#else
#define USE_FLANIMATED_IMAGE    0
#endif

#endif /* PINFLAnimatedImageCheck_h */
