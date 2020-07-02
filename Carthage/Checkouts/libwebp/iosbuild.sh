#!/bin/bash
#
# This script generates 'WebP.framework' and 'WebPDecoder.framework'. An iOS
# app can decode WebP images by including 'WebPDecoder.framework' and both
# encode and decode WebP images by including 'WebP.framework'.
#
# Run ./iosbuild.sh to generate the frameworks under the current directory
# (the previous build will be erased if it exists).
#
# This script is inspired by the build script written by Carson McDonald.
# (http://www.ioncannon.net/programming/1483/using-webp-to-reduce-native-ios-app-size/).

set -e

# Extract the latest SDK version from the final field of the form: iphoneosX.Y
readonly SDK=$(xcodebuild -showsdks \
  | grep iphoneos | sort | tail -n 1 | awk '{print substr($NF, 9)}'
)
# Extract Xcode version.
readonly XCODE=$(xcodebuild -version | grep Xcode | cut -d " " -f2)
if [[ -z "${XCODE}" ]]; then
  echo "Xcode not available"
  exit 1
fi

readonly OLDPATH=${PATH}

# Add iPhoneOS-V6 to the list of platforms below if you need armv6 support.
# Note that iPhoneOS-V6 support is not available with the iOS6 SDK.
PLATFORMS="iPhoneSimulator iPhoneSimulator64"
PLATFORMS+=" iPhoneOS-V7 iPhoneOS-V7s iPhoneOS-V7-arm64"
readonly PLATFORMS
readonly SRCDIR=$(dirname $0)
readonly TOPDIR=$(pwd)
readonly BUILDDIR="${TOPDIR}/iosbuild"
readonly TARGETDIR="${TOPDIR}/WebP.framework"
readonly DECTARGETDIR="${TOPDIR}/WebPDecoder.framework"
readonly MUXTARGETDIR="${TOPDIR}/WebPMux.framework"
readonly DEMUXTARGETDIR="${TOPDIR}/WebPDemux.framework"
readonly DEVELOPER=$(xcode-select --print-path)
readonly PLATFORMSROOT="${DEVELOPER}/Platforms"
readonly LIPO=$(xcrun -sdk iphoneos${SDK} -find lipo)
LIBLIST=''
DECLIBLIST=''
MUXLIBLIST=''
DEMUXLIBLIST=''

if [[ -z "${SDK}" ]]; then
  echo "iOS SDK not available"
  exit 1
elif [[ ${SDK%%.*} -gt 8 ]]; then
  EXTRA_CFLAGS="-fembed-bitcode"
elif [[ ${SDK} < 6.0 ]]; then
  echo "You need iOS SDK version 6.0 or above"
  exit 1
else
  echo "iOS SDK Version ${SDK}"
fi

rm -rf ${BUILDDIR} ${TARGETDIR} ${DECTARGETDIR} \
    ${MUXTARGETDIR} ${DEMUXTARGETDIR}
mkdir -p ${BUILDDIR} ${TARGETDIR}/Headers/ ${DECTARGETDIR}/Headers/ \
    ${MUXTARGETDIR}/Headers/ ${DEMUXTARGETDIR}/Headers/

if [[ ! -e ${SRCDIR}/configure ]]; then
  if ! (cd ${SRCDIR} && sh autogen.sh); then
    cat <<EOT
Error creating configure script!
This script requires the autoconf/automake and libtool to build. MacPorts can
be used to obtain these:
http://www.macports.org/install.php
EOT
    exit 1
  fi
fi

for PLATFORM in ${PLATFORMS}; do
  ARCH2=""
  if [[ "${PLATFORM}" == "iPhoneOS-V7-arm64" ]]; then
    PLATFORM="iPhoneOS"
    ARCH="aarch64"
    ARCH2="arm64"
  elif [[ "${PLATFORM}" == "iPhoneOS-V7s" ]]; then
    PLATFORM="iPhoneOS"
    ARCH="armv7s"
  elif [[ "${PLATFORM}" == "iPhoneOS-V7" ]]; then
    PLATFORM="iPhoneOS"
    ARCH="armv7"
  elif [[ "${PLATFORM}" == "iPhoneOS-V6" ]]; then
    PLATFORM="iPhoneOS"
    ARCH="armv6"
  elif [[ "${PLATFORM}" == "iPhoneSimulator64" ]]; then
    PLATFORM="iPhoneSimulator"
    ARCH="x86_64"
  else
    ARCH="i386"
  fi

  ROOTDIR="${BUILDDIR}/${PLATFORM}-${SDK}-${ARCH}"
  mkdir -p "${ROOTDIR}"

  DEVROOT="${DEVELOPER}/Toolchains/XcodeDefault.xctoolchain"
  SDKROOT="${PLATFORMSROOT}/"
  SDKROOT+="${PLATFORM}.platform/Developer/SDKs/${PLATFORM}${SDK}.sdk/"
  CFLAGS="-arch ${ARCH2:-${ARCH}} -pipe -isysroot ${SDKROOT} -O3 -DNDEBUG"
  CFLAGS+=" -miphoneos-version-min=6.0 ${EXTRA_CFLAGS}"

  set -x
  export PATH="${DEVROOT}/usr/bin:${OLDPATH}"
  ${SRCDIR}/configure --host=${ARCH}-apple-darwin --prefix=${ROOTDIR} \
    --build=$(${SRCDIR}/config.guess) \
    --disable-shared --enable-static \
    --enable-libwebpdecoder --enable-swap-16bit-csp \
    --enable-libwebpmux \
    CFLAGS="${CFLAGS}"
  set +x

  # run make only in the src/ directory to create libwebp.a/libwebpdecoder.a
  cd src/
  make V=0
  make install

  LIBLIST+=" ${ROOTDIR}/lib/libwebp.a"
  DECLIBLIST+=" ${ROOTDIR}/lib/libwebpdecoder.a"
  MUXLIBLIST+=" ${ROOTDIR}/lib/libwebpmux.a"
  DEMUXLIBLIST+=" ${ROOTDIR}/lib/libwebpdemux.a"

  make clean
  cd ..

  export PATH=${OLDPATH}
done

echo "LIBLIST = ${LIBLIST}"
cp -a ${SRCDIR}/src/webp/{decode,encode,types}.h ${TARGETDIR}/Headers/
${LIPO} -create ${LIBLIST} -output ${TARGETDIR}/WebP

echo "DECLIBLIST = ${DECLIBLIST}"
cp -a ${SRCDIR}/src/webp/{decode,types}.h ${DECTARGETDIR}/Headers/
${LIPO} -create ${DECLIBLIST} -output ${DECTARGETDIR}/WebPDecoder

echo "MUXLIBLIST = ${MUXLIBLIST}"
cp -a ${SRCDIR}/src/webp/{types,mux,mux_types}.h \
    ${MUXTARGETDIR}/Headers/
${LIPO} -create ${MUXLIBLIST} -output ${MUXTARGETDIR}/WebPMux

echo "DEMUXLIBLIST = ${DEMUXLIBLIST}"
cp -a ${SRCDIR}/src/webp/{decode,types,mux_types,demux}.h \
    ${DEMUXTARGETDIR}/Headers/
${LIPO} -create ${DEMUXLIBLIST} -output ${DEMUXTARGETDIR}/WebPDemux
