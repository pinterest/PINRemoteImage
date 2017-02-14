apple_library(
  name = 'PINCache',
  exported_headers = glob(['Source/*.h']),
  # PINDiskCache.m should be compiled with '-fobjc-arc-exceptions' (#105)
  srcs =
    glob(['Source/*.m'], excludes = ['Source/PINDiskCache.m']) +
    [('Source/PINDiskCache.m', ['-fobjc-arc-exceptions'])],
  preprocessor_flags = ['-fobjc-arc'],
  lang_preprocessor_flags = {
    'C': ['-std=gnu99'],
    'CXX': ['-std=gnu++11', '-stdlib=libc++'],
  },
  linker_flags = [
    '-weak_framework',
    'UIKit',
    '-weak_framework',
    'AppKit',
  ],
  frameworks = [
    '$SDKROOT/System/Library/Frameworks/Foundation.framework',
  ],
  visibility = ['PUBLIC'],
)
