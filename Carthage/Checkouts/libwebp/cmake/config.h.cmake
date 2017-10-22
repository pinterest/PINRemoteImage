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
include(${CMAKE_CURRENT_LIST_DIR}/cpu.cmake)

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
configure_file(${CMAKE_CURRENT_LIST_DIR}/config.h.in
  ${CMAKE_CURRENT_BINARY_DIR}/include/webp/config.h)
add_definitions(-DHAVE_CONFIG_H)
# The webp folder is included as we reference config.h as
# ../webp/config.h or webp/config.h
include_directories(${CMAKE_CURRENT_BINARY_DIR}/include
  ${CMAKE_CURRENT_BINARY_DIR}/include/webp
)
