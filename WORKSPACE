load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

http_archive(
    name = "libwebp",
    build_file_content = """
PUBLIC_HEADERS = [
    "src/webp/**/decode.h",
    "src/webp/**/encode.h",
    "src/webp/**/types.h",
    "src/webp/**/mux_types.h",
    "src/webp/**/format_constants.h",
    "src/webp/**/demux.h",
    "src/webp/**/mux.h"
]

objc_library(
    name = "webp",
    srcs = glob(["src/**/*.c", "src/**/*.h"], PUBLIC_HEADERS, allow_empty = False),
    hdrs = glob(PUBLIC_HEADERS, allow_empty = False),
    includes = [
        "src",
        "src/dec",
    ],
    defines = [
        "_THREAD_SAFE"
    ],
    visibility = [
        "//visibility:public"
    ]
)
    """,
    sha256 = "01bcde6a40a602294994050b81df379d71c40b7e39c819c024d079b3c56307f4",
    strip_prefix = "libwebp-1.2.1",
    url = "https://github.com/webmproject/libwebp/archive/refs/tags/v1.2.1.tar.gz",
)
