apple_library(
  name = 'PINOperation',
  modular = True,
  exported_headers = glob(['Source/*.h']),
  srcs =
    glob(['Source/*.m']),
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
