cmake_minimum_required(VERSION 2.8.7)

project(libwebp C)

# Options for coder / decoder executables.
option(WEBP_BUILD_CWEBP "Build the cwebp command line tool." OFF)
option(WEBP_BUILD_DWEBP "Build the dwebp command line tool." OFF)
option(WEBP_EXPERIMENTAL_FEATURES "Build with experimental features." OFF)
option(WEBP_FORCE_ALIGNED "Force aligned memory operations." OFF)

set(WEBP_DEP_LIBRARIES)
set(WEBP_DEP_INCLUDE_DIRS)

if(NOT CMAKE_BUILD_TYPE)
  set(CMAKE_BUILD_TYPE "Release" CACHE
    "Build type: Release, Debug or RelWithDebInfo" STRING FORCE
  )
endif()

################################################################################
# Generate the config.h to compile with specific intrinsics / libs.

## Check for compiler options.
include(CheckCSourceCompiles)
check_c_source_compiles("
    int main(void) {
      (void)__builtin_bswap16(0);
      return 0;
    }
  "
  HAVE_BUILTIN_BSWAP16
)
check_c_source_compiles("
    int main(void) {
      (void)__builtin_bswap32(0);
      return 0;
    }
  "
  HAVE_BUILTIN_BSWAP32
)
check_c_source_compiles("
    int main(void) {
      (void)__builtin_bswap64(0);
      return 0;
    }
  "
  HAVE_BUILTIN_BSWAP64
)

## Check for libraries.
find_package(Threads)
if(Threads_FOUND)
  if(CMAKE_USE_PTHREADS_INIT)
    set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -pthread")
  endif()
  foreach(PTHREAD_TEST HAVE_PTHREAD_PRIO_INHERIT PTHREAD_CREATE_UNDETACHED)
    check_c_source_compiles("
        #include <pthread.h>
        int main (void) {
          int attr = ${PTHREAD_TEST};
          return attr;
        }
      " ${PTHREAD_TEST}
    )
  endforeach()
  list(APPEND WEBP_DEP_LIBRARIES ${CMAKE_THREAD_LIBS_INIT})
endif()
set(WEBP_USE_THREAD ${Threads_FOUND})

# TODO: this seems unused, check with autotools.
set(LT_OBJDIR ".libs/")

# Only useful for vwebp, so useless for now.
# find_package(OpenGL)
# set(WEBP_HAVE_GL ${OPENGL_FOUND})
# set(WEBP_DEP_INCLUDE_DIRS ${WEBP_DEP_INCLUDE_DIRS} ${OPENGL_INCLUDE_DIRS})
# set(WEBP_DEP_LIBRARIES ${WEBP_DEP_LIBRARIES} ${OPENGL_LIBRARIES})

# Find the standard C math library.
find_library(MATH_LIBRARY NAMES m)
if(MATH_LIBRARY)
  list(APPEND WEBP_DEP_LIBRARIES ${MATH_LIBRARY})
endif()

# Find the standard image libraries.
set(WEBP_DEP_IMG_LIBRARIES)
set(WEBP_DEP_IMG_INCLUDE_DIRS)
foreach(I_LIB PNG JPEG TIFF GIF)
  find_package(${I_LIB})
  set(WEBP_HAVE_${I_LIB} ${${I_LIB}_FOUND})
  if(${I_LIB}_FOUND)
    list(APPEND WEBP_DEP_IMG_LIBRARIES ${${I_LIB}_LIBRARIES})
    list(APPEND WEBP_DEP_IMG_INCLUDE_DIRS ${${I_LIB}_INCLUDE_DIRS})
  endif()
endforeach()

## Check for specific headers.
include(CheckIncludeFiles)
check_include_files("stdlib.h;stdarg.h;string.h;float.h" STDC_HEADERS)
check_include_files(dlfcn.h HAVE_DLFCN_H)
check_include_files(GLUT/glut.h HAVE_GLUT_GLUT_H)
check_include_files(GL/glut.h HAVE_GL_GLUT_H)
check_include_files(inttypes.h HAVE_INTTYPES_H)
check_include_files(memory.h HAVE_MEMORY_H)
check_include_files(OpenGL/glut.h HAVE_OPENGL_GLUT_H)
check_include_files(shlwapi.h HAVE_SHLWAPI_H)
check_include_files(stdint.h HAVE_STDINT_H)
check_include_files(stdlib.h HAVE_STDLIB_H)
check_include_files(strings.h HAVE_STRINGS_H)
check_include_files(string.h HAVE_STRING_H)
check_include_files(sys/stat.h HAVE_SYS_STAT_H)
check_include_files(sys/types.h HAVE_SYS_TYPES_H)
check_include_files(unistd.h HAVE_UNISTD_H)
check_include_files(wincodec.h HAVE_WINCODEC_H)
check_include_files(windows.h HAVE_WINDOWS_H)

# Windows specifics
if(HAVE_WINCODEC_H)
  list(APPEND WEBP_DEP_LIBRARIES shlwapi ole32 windowscodecs)
endif()

## Check for SIMD extensions.
set(WEBP_SIMD_FLAGS "SSE2;SSE41;AVX2")
set(WEBP_SIMD_FILE_EXTENSIONS "_sse2.c;_sse41.c;_avx2.c")
if(MSVC)
  # MSVC does not have a SSE4 flag but AVX2 support implies
  # SSE4 support.
  set(SIMD_ENABLE_FLAGS "/arch:SSE2;/arch:AVX2;/arch:AVX2")
  set(SIMD_DISABLE_FLAGS)
else()
  set(SIMD_ENABLE_FLAGS "-msse2;-msse4.1;-mavx2")
  set(SIMD_DISABLE_FLAGS "-mno-sse2;-mno-sse4.1;-mno-avx2")
endif()

set(WEBP_SIMD_FILES_TO_NOT_INCLUDE)
set(WEBP_SIMD_FILES_TO_INCLUDE)
set(WEBP_SIMD_FLAGS_TO_INCLUDE)

list(LENGTH WEBP_SIMD_FLAGS WEBP_SIMD_FLAGS_LENGTH)
math(EXPR WEBP_SIMD_FLAGS_RANGE "${WEBP_SIMD_FLAGS_LENGTH} - 1")

foreach(I_SIMD RANGE ${WEBP_SIMD_FLAGS_RANGE})
  list(GET WEBP_SIMD_FLAGS ${I_SIMD} WEBP_SIMD_FLAG)
  list(GET SIMD_ENABLE_FLAGS ${I_SIMD} SIMD_COMPILE_FLAG)
  set(CMAKE_REQUIRED_FLAGS ${SIMD_COMPILE_FLAG})
  check_c_source_compiles("
      #include \"${CMAKE_CURRENT_LIST_DIR}/src/dsp/dsp.h\"
      int main(void) {
        #if !defined(WEBP_USE_${WEBP_SIMD_FLAG})
        this is not valid code
        #endif
        return 0;
      }
    "
    WEBP_HAVE_${WEBP_SIMD_FLAG}
  )

  # Check which files we should include or not.
  list(GET WEBP_SIMD_FILE_EXTENSIONS ${I_SIMD} WEBP_SIMD_FILE_EXTENSION)
  file(GLOB SIMD_FILES RELATIVE ${CMAKE_CURRENT_LIST_DIR}
    "${CMAKE_CURRENT_SOURCE_DIR}/src/dsp/*${WEBP_SIMD_FILE_EXTENSION}"
  )
  if(WEBP_HAVE_${WEBP_SIMD_FLAG})
    # Memorize the file and flags.
    foreach(FILE ${SIMD_FILES})
      list(APPEND WEBP_SIMD_FILES_TO_INCLUDE ${FILE})
      list(APPEND WEBP_SIMD_FLAGS_TO_INCLUDE ${SIMD_COMPILE_FLAG})
    endforeach()
  else()
    # Remove the file from the list.
    foreach(FILE ${SIMD_FILES})
      list(APPEND WEBP_SIMD_FILES_NOT_TO_INCLUDE ${FILE})
    endforeach()
    # Explicitly disable SIMD.
    if(SIMD_DISABLE_FLAGS)
      list(GET SIMD_DISABLE_FLAGS ${I_SIMD} SIMD_COMPILE_FLAG)
      include(CheckCCompilerFlag)
      check_c_compiler_flag(${SIMD_COMPILE_FLAG} HAS_COMPILE_FLAG)
      if(HAS_COMPILE_FLAG)
        set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} ${SIMD_COMPILE_FLAG}")
      endif()
    endif()
  endif()
endforeach()

## Define extra info.
set(PACKAGE ${PROJECT_NAME})
set(PACKAGE_NAME ${PROJECT_NAME})

# Read from configure.ac.
file(READ ${CMAKE_CURRENT_SOURCE_DIR}/configure.ac CONFIGURE_AC)
string(REGEX MATCHALL "\\[([0-9a-z\\.:/]*)\\]"
  CONFIGURE_AC_PACKAGE_INFO ${CONFIGURE_AC}
)
function(strip_bracket VAR)
  string(LENGTH ${${VAR}} TMP_LEN)
  math(EXPR TMP_LEN ${TMP_LEN}-2)
  string(SUBSTRING ${${VAR}} 1 ${TMP_LEN} TMP_SUB)
  set(${VAR} ${TMP_SUB} PARENT_SCOPE)
endfunction()

list(GET CONFIGURE_AC_PACKAGE_INFO 1 PACKAGE_VERSION)
strip_bracket(PACKAGE_VERSION)
list(GET CONFIGURE_AC_PACKAGE_INFO 2 PACKAGE_BUGREPORT)
strip_bracket(PACKAGE_BUGREPORT)
list(GET CONFIGURE_AC_PACKAGE_INFO 3 PACKAGE_URL)
strip_bracket(PACKAGE_URL)

# Build more info.
set(PACKAGE_STRING "${PACKAGE_NAME} ${PACKAGE_VERSION}")
set(PACKAGE_TARNAME ${PACKAGE_NAME})
set(VERSION ${PACKAGE_VERSION})

## Generate the config.h header.
configure_file(${CMAKE_CURRENT_LIST_DIR}/cmake/config.h.in
  ${CMAKE_CURRENT_BINARY_DIR}/include/webp/config.h)
add_definitions(-DHAVE_CONFIG_H)
# The webp folder is included as we reference config.h as
# ../webp/config.h or webp/config.h
include_directories(${CMAKE_CURRENT_BINARY_DIR}/include
  ${CMAKE_CURRENT_BINARY_DIR}/include/webp
)


################################################################################
# WebP source files.
# Read the Makefile.am to get the source files.
set(WEBP_SRCS)

function(parse_Makefile_am FOLDER WEBP_SRCS)
  file(READ ${FOLDER}/Makefile.am MAKEFILE_AM)
  string(REGEX MATCHALL "_SOURCES \\+= [^\n]*"
    FILES_PER_LINE ${MAKEFILE_AM}
  )
  set(SRCS ${WEBP_SRCS})
  foreach(FILES ${FILES_PER_LINE})
    string(SUBSTRING ${FILES} 12 -1 FILES)
    string(REGEX MATCHALL "[0-9a-z\\._]+"
      FILES ${FILES}
    )
    foreach(FILE ${FILES})
      list(APPEND SRCS ${FOLDER}/${FILE})
    endforeach()
  endforeach()
  set(WEBP_SRCS ${SRCS} PARENT_SCOPE)
endfunction()

parse_Makefile_am(${CMAKE_CURRENT_SOURCE_DIR}/src/dec "${WEBP_SRCS}")
parse_Makefile_am(${CMAKE_CURRENT_SOURCE_DIR}/src/demux "${WEBP_SRCS}")
parse_Makefile_am(${CMAKE_CURRENT_SOURCE_DIR}/src/dsp "${WEBP_SRCS}")
parse_Makefile_am(${CMAKE_CURRENT_SOURCE_DIR}/src/enc "${WEBP_SRCS}")
parse_Makefile_am(${CMAKE_CURRENT_SOURCE_DIR}/src/utils "${WEBP_SRCS}")

# Remove the files specific to SIMD we don't user.
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
if(WEBP_BUILD_CWEBP OR WEBP_BUILD_DWEBP)
  # Example utility library.
  set(exampleutil_SRCS
    ${CMAKE_CURRENT_SOURCE_DIR}/examples/example_util.c
    ${CMAKE_CURRENT_SOURCE_DIR}/examples/example_util.h
    ${CMAKE_CURRENT_SOURCE_DIR}/examples/stopwatch.h)
  add_library(exampleutil ${exampleutil_SRCS})
  target_link_libraries(exampleutil webp ${WEBP_DEP_LIBRARIES})
endif()

if(WEBP_BUILD_CWEBP)
  # Image-decoding utility library.
  set(exampledec_SRCS
    ${CMAKE_CURRENT_SOURCE_DIR}/examples/image_dec.c
    ${CMAKE_CURRENT_SOURCE_DIR}/examples/image_dec.h
    ${CMAKE_CURRENT_SOURCE_DIR}/examples/jpegdec.c
    ${CMAKE_CURRENT_SOURCE_DIR}/examples/jpegdec.h
    ${CMAKE_CURRENT_SOURCE_DIR}/examples/metadata.c
    ${CMAKE_CURRENT_SOURCE_DIR}/examples/metadata.h
    ${CMAKE_CURRENT_SOURCE_DIR}/examples/pngdec.c
    ${CMAKE_CURRENT_SOURCE_DIR}/examples/pngdec.h
    ${CMAKE_CURRENT_SOURCE_DIR}/examples/tiffdec.c
    ${CMAKE_CURRENT_SOURCE_DIR}/examples/tiffdec.h
    ${CMAKE_CURRENT_SOURCE_DIR}/examples/webpdec.c
    ${CMAKE_CURRENT_SOURCE_DIR}/examples/webpdec.h
    ${CMAKE_CURRENT_SOURCE_DIR}/examples/wicdec.c
    ${CMAKE_CURRENT_SOURCE_DIR}/examples/wicdec.h)
  add_library(exampledec ${exampledec_SRCS})
  target_link_libraries(exampledec webp ${WEBP_DEP_LIBRARIES}
    ${WEBP_DEP_IMG_LIBRARIES})
endif()

if(WEBP_BUILD_DWEBP)
  # dwebp
  include_directories(${WEBP_DEP_IMG_INCLUDE_DIRS})
  add_executable(dwebp
    ${CMAKE_CURRENT_SOURCE_DIR}/examples/dwebp.c
    ${CMAKE_CURRENT_SOURCE_DIR}/examples/stopwatch.h
  )
  target_link_libraries(dwebp webp exampleutil ${WEBP_DEP_LIBRARIES}
    ${WEBP_DEP_IMG_LIBRARIES}
  )
endif()

if(WEBP_BUILD_CWEBP)
  # cwebp
  include_directories(${WEBP_DEP_IMG_INCLUDE_DIRS})
  add_executable(cwebp
    ${CMAKE_CURRENT_SOURCE_DIR}/examples/cwebp.c
    ${CMAKE_CURRENT_SOURCE_DIR}/examples/stopwatch.h)
  target_link_libraries(cwebp exampledec webp exampleutil
    ${WEBP_DEP_LIBRARIES} ${WEBP_DEP_IMG_LIBRARIES}
  )
endif()
