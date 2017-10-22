cmake_minimum_required(VERSION 2.8.7)

project(libwebp C)

# Options for coder / decoder executables.
option(WEBP_BUILD_CWEBP "Build the cwebp command line tool." OFF)
option(WEBP_BUILD_DWEBP "Build the dwebp command line tool." OFF)
option(WEBP_BUILD_GIF2WEBP "Build the gif2webp conversion tool." OFF)
option(WEBP_BUILD_IMG2WEBP "Build the img2webp animation tool." OFF)
option(WEBP_EXPERIMENTAL_FEATURES "Build with experimental features." OFF)
option(WEBP_ENABLE_SWAP_16BIT_CSP "Enable byte swap for 16 bit colorspaces." OFF)

set(WEBP_DEP_LIBRARIES)
set(WEBP_DEP_INCLUDE_DIRS)

if(NOT CMAKE_BUILD_TYPE)
  set(CMAKE_BUILD_TYPE "Release" CACHE
    "Build type: Release, Debug or RelWithDebInfo" STRING FORCE
  )
endif()

include(cmake/config.h.cmake)

################################################################################
# Options.
if(WEBP_ENABLE_SWAP_16BIT_CSP)
  add_definitions(-DWEBP_SWAP_16BIT_CSP)
endif()

################################################################################
# Android only.
if(ANDROID)
  include_directories(${ANDROID_NDK}/sources/android/cpufeatures)
  add_library(cpufeatures STATIC
    ${ANDROID_NDK}/sources/android/cpufeatures/cpu-features.c
  )
  target_link_libraries(cpufeatures dl)
  set(WEBP_DEP_LIBRARIES ${WEBP_DEP_LIBRARIES} cpufeatures)
  set(WEBP_DEP_INCLUDE_DIRS ${WEBP_DEP_INCLUDE_DIRS}
    ${ANDROID_NDK}/sources/android/cpufeatures
  )
endif()

################################################################################
# WebP source files.
# Read the Makefile.am to get the source files.

function(parse_Makefile_am FOLDER VAR)
  file(READ ${FOLDER}/Makefile.am MAKEFILE_AM)
  string(REGEX MATCHALL "_SOURCES \\+= [^\n]*"
    FILES_PER_LINE ${MAKEFILE_AM}
  )
  set(SRCS ${${VAR}})
  foreach(FILES ${FILES_PER_LINE})
    string(SUBSTRING ${FILES} 12 -1 FILES)
    string(REGEX MATCHALL "[0-9a-z\\._]+"
      FILES ${FILES}
    )
    foreach(FILE ${FILES})
      list(APPEND SRCS ${FOLDER}/${FILE})
    endforeach()
  endforeach()
  set(${VAR} ${SRCS} PARENT_SCOPE)
endfunction()

set(WEBP_SRCS)
parse_Makefile_am(${CMAKE_CURRENT_SOURCE_DIR}/src/dec "WEBP_SRCS")
parse_Makefile_am(${CMAKE_CURRENT_SOURCE_DIR}/src/demux "WEBP_SRCS")
parse_Makefile_am(${CMAKE_CURRENT_SOURCE_DIR}/src/dsp "WEBP_SRCS")
parse_Makefile_am(${CMAKE_CURRENT_SOURCE_DIR}/src/enc "WEBP_SRCS")
parse_Makefile_am(${CMAKE_CURRENT_SOURCE_DIR}/src/utils "WEBP_SRCS")

# Remove the files specific to SIMD we don't use.
foreach(FILE ${WEBP_SIMD_FILES_NOT_TO_INCLUDE})
  list(REMOVE_ITEM WEBP_SRCS ${FILE})
endforeach()

# Build the library.
add_definitions(-Wall)
include_directories(${CMAKE_CURRENT_SOURCE_DIR}/src/ ${WEBP_DEP_INCLUDE_DIRS})
add_library(webp ${WEBP_SRCS})
target_link_libraries(webp ${WEBP_DEP_LIBRARIES})

# Change the compile flags for SIMD files we use.
list(LENGTH WEBP_SIMD_FILES_TO_INCLUDE WEBP_SIMD_FILES_TO_INCLUDE_LENGTH)
math(EXPR WEBP_SIMD_FILES_TO_INCLUDE_RANGE
  "${WEBP_SIMD_FILES_TO_INCLUDE_LENGTH}-1"
)

foreach(I_FILE RANGE ${WEBP_SIMD_FILES_TO_INCLUDE_RANGE})
  list(GET WEBP_SIMD_FILES_TO_INCLUDE ${I_FILE} FILE)
  list(GET WEBP_SIMD_FLAGS_TO_INCLUDE ${I_FILE} SIMD_COMPILE_FLAG)
  set_source_files_properties(${FILE} PROPERTIES
    COMPILE_FLAGS ${SIMD_COMPILE_FLAG}
  )
endforeach()

# Build the executables if asked for.
if(WEBP_BUILD_CWEBP OR WEBP_BUILD_DWEBP OR
   WEBP_BUILD_GIF2WEBP OR WEBP_BUILD_IMG2WEBP)
  # Example utility library.
  set(exampleutil_SRCS
    ${CMAKE_CURRENT_SOURCE_DIR}/examples/stopwatch.h
    ${CMAKE_CURRENT_SOURCE_DIR}/examples/example_util.c
    ${CMAKE_CURRENT_SOURCE_DIR}/examples/example_util.h)
  add_library(exampleutil ${exampleutil_SRCS})
  target_link_libraries(exampleutil webp ${WEBP_DEP_LIBRARIES})

  set(imageioutil_SRCS
    ${CMAKE_CURRENT_SOURCE_DIR}/imageio/imageio_util.c
    ${CMAKE_CURRENT_SOURCE_DIR}/imageio/imageio_util.h)
  add_library(imageioutil ${imageioutil_SRCS})
  target_link_libraries(imageioutil ${WEBP_DEP_LIBRARIES})

  # Image-decoding utility library.
  set(imagedec_SRCS
    ${CMAKE_CURRENT_SOURCE_DIR}/examples/gifdec.c
    ${CMAKE_CURRENT_SOURCE_DIR}/examples/gifdec.h
    ${CMAKE_CURRENT_SOURCE_DIR}/imageio/image_dec.c
    ${CMAKE_CURRENT_SOURCE_DIR}/imageio/image_dec.h
    ${CMAKE_CURRENT_SOURCE_DIR}/imageio/jpegdec.c
    ${CMAKE_CURRENT_SOURCE_DIR}/imageio/jpegdec.h
    ${CMAKE_CURRENT_SOURCE_DIR}/imageio/metadata.c
    ${CMAKE_CURRENT_SOURCE_DIR}/imageio/metadata.h
    ${CMAKE_CURRENT_SOURCE_DIR}/imageio/pngdec.c
    ${CMAKE_CURRENT_SOURCE_DIR}/imageio/pngdec.h
    ${CMAKE_CURRENT_SOURCE_DIR}/imageio/tiffdec.c
    ${CMAKE_CURRENT_SOURCE_DIR}/imageio/tiffdec.h
    ${CMAKE_CURRENT_SOURCE_DIR}/imageio/webpdec.c
    ${CMAKE_CURRENT_SOURCE_DIR}/imageio/webpdec.h
    ${CMAKE_CURRENT_SOURCE_DIR}/imageio/wicdec.c
    ${CMAKE_CURRENT_SOURCE_DIR}/imageio/wicdec.h)
  add_library(imagedec ${imagedec_SRCS})
  target_link_libraries(imagedec webp ${WEBP_DEP_LIBRARIES}
    ${WEBP_DEP_IMG_LIBRARIES})

  # Image-encoding utility library.
  set(imageenc_SRCS
    ${CMAKE_CURRENT_SOURCE_DIR}/imageio/image_enc.c
    ${CMAKE_CURRENT_SOURCE_DIR}/imageio/image_enc.h)
  add_library(imageenc ${imageenc_SRCS})
  target_link_libraries(imageenc webp imageioutil
    ${WEBP_DEP_LIBRARIES} ${WEBP_DEP_IMG_LIBRARIES})
endif()

if(WEBP_BUILD_DWEBP)
  # dwebp
  include_directories(${WEBP_DEP_IMG_INCLUDE_DIRS})
  add_executable(dwebp
    ${CMAKE_CURRENT_SOURCE_DIR}/examples/dwebp.c
    ${CMAKE_CURRENT_SOURCE_DIR}/examples/stopwatch.h)
  target_link_libraries(dwebp imagedec imageenc webp
    exampleutil imageioutil
    ${WEBP_DEP_LIBRARIES} ${WEBP_DEP_IMG_LIBRARIES}
  )
endif()

if(WEBP_BUILD_CWEBP)
  # cwebp
  include_directories(${WEBP_DEP_IMG_INCLUDE_DIRS})
  add_executable(cwebp
    ${CMAKE_CURRENT_SOURCE_DIR}/examples/cwebp.c
    ${CMAKE_CURRENT_SOURCE_DIR}/examples/stopwatch.h)
  target_link_libraries(cwebp imagedec webp exampleutil imageioutil
    ${WEBP_DEP_LIBRARIES} ${WEBP_DEP_IMG_LIBRARIES}
  )
endif()

if(WEBP_BUILD_GIF2WEBP)
  # gif2webp
  include_directories(${WEBP_DEP_IMG_INCLUDE_DIRS})
  set(GIF2WEBP_SRCS ${CMAKE_CURRENT_SOURCE_DIR}/examples/gif2webp.c)
  parse_Makefile_am(${CMAKE_CURRENT_SOURCE_DIR}/src/mux "GIF2WEBP_SRCS")
  add_executable(gif2webp ${GIF2WEBP_SRCS})
  target_link_libraries(gif2webp imagedec webp exampleutil imageioutil
    ${WEBP_DEP_LIBRARIES} ${WEBP_DEP_IMG_LIBRARIES}
  )
endif()

if(WEBP_BUILD_IMG2WEBP)
  # img2webp
  include_directories(${WEBP_DEP_IMG_INCLUDE_DIRS})
  set(IMG2WEBP_SRCS ${CMAKE_CURRENT_SOURCE_DIR}/examples/img2webp.c)
  parse_Makefile_am(${CMAKE_CURRENT_SOURCE_DIR}/src/mux "IMG2WEBP_SRCS")
  add_executable(img2webp ${IMG2WEBP_SRCS})
  target_link_libraries(img2webp imagedec webp exampleutil imageioutil
    ${WEBP_DEP_LIBRARIES} ${WEBP_DEP_IMG_LIBRARIES}
  )
endif()
