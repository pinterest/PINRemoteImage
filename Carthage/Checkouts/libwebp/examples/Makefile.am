AM_CPPFLAGS += -I$(top_builddir)/src -I$(top_srcdir)/src

bin_PROGRAMS = dwebp cwebp
if BUILD_VWEBP
  bin_PROGRAMS += vwebp
endif
if WANT_MUX
  bin_PROGRAMS += webpmux
endif

if BUILD_GIF2WEBP
  bin_PROGRAMS += gif2webp
endif

noinst_LTLIBRARIES = libexampleutil.la libexampledec.la

libexampleutil_la_SOURCES = example_util.c example_util.h stopwatch.h

libexampledec_la_SOURCES  = image_dec.c image_dec.h
libexampledec_la_SOURCES += jpegdec.c jpegdec.h
libexampledec_la_SOURCES += metadata.c metadata.h
libexampledec_la_SOURCES += pngdec.c pngdec.h
libexampledec_la_SOURCES += tiffdec.c tiffdec.h
libexampledec_la_SOURCES += webpdec.c webpdec.h
libexampledec_la_SOURCES += wicdec.c wicdec.h
libexampledec_la_CPPFLAGS = $(JPEG_INCLUDES) $(PNG_INCLUDES) $(TIFF_INCLUDES)
libexampledec_la_CPPFLAGS += $(AM_CPPFLAGS) $(USE_EXPERIMENTAL_CODE)

if BUILD_ANIMDIFF
  noinst_PROGRAMS = anim_diff
endif

anim_diff_SOURCES = anim_diff.c anim_util.c anim_util.h
anim_diff_CPPFLAGS = $(AM_CPPFLAGS) $(USE_EXPERIMENTAL_CODE) $(GIF_INCLUDES)
anim_diff_LDADD  = ../src/demux/libwebpdemux.la
anim_diff_LDADD += libexampleutil.la
anim_diff_LDADD += $(GIF_LIBS) -lm

dwebp_SOURCES = dwebp.c stopwatch.h
dwebp_CPPFLAGS  = $(AM_CPPFLAGS) $(USE_EXPERIMENTAL_CODE)
dwebp_CPPFLAGS += $(JPEG_INCLUDES) $(PNG_INCLUDES)
dwebp_LDADD = libexampleutil.la $(PNG_LIBS) $(JPEG_LIBS)

cwebp_SOURCES  = cwebp.c stopwatch.h
cwebp_CPPFLAGS  = $(AM_CPPFLAGS) $(USE_EXPERIMENTAL_CODE)
cwebp_LDADD  = libexampleutil.la libexampledec.la ../src/libwebp.la
cwebp_LDADD += $(JPEG_LIBS) $(PNG_LIBS) $(TIFF_LIBS)

gif2webp_SOURCES = gif2webp.c gifdec.c gifdec.h
gif2webp_CPPFLAGS = $(AM_CPPFLAGS) $(USE_EXPERIMENTAL_CODE) $(GIF_INCLUDES)
gif2webp_LDADD  = libexampleutil.la ../src/mux/libwebpmux.la ../src/libwebp.la
gif2webp_LDADD += $(GIF_LIBS)

webpmux_SOURCES = webpmux.c
webpmux_CPPFLAGS = $(AM_CPPFLAGS) $(USE_EXPERIMENTAL_CODE)
webpmux_LDADD = libexampleutil.la ../src/mux/libwebpmux.la ../src/libwebp.la

vwebp_SOURCES = vwebp.c
vwebp_CPPFLAGS = $(AM_CPPFLAGS) $(USE_EXPERIMENTAL_CODE) $(GL_INCLUDES)
vwebp_LDADD = libexampleutil.la ../src/demux/libwebpdemux.la $(GL_LIBS)

if BUILD_LIBWEBPDECODER
  anim_diff_LDADD += ../src/libwebpdecoder.la
  dwebp_LDADD += ../src/libwebpdecoder.la
  vwebp_LDADD += ../src/libwebpdecoder.la
else
  anim_diff_LDADD += ../src/libwebp.la
  dwebp_LDADD += ../src/libwebp.la
  vwebp_LDADD += ../src/libwebp.la
endif
