PLATFORM="platform=iOS Simulator,name=iPhone 11"
SDK="iphonesimulator"
SHELL=/bin/bash -o pipefail
XCODE_MAJOR_VERSION=$(shell xcodebuild -version | HEAD -n 1 | sed -E 's/Xcode ([0-9]+).*/\1/')

.PHONY: all webp cocoapods test carthage analyze spm

cocoapods:
	pod lib lint
	
analyze:
	xcodebuild clean analyze -destination ${PLATFORM} -sdk ${SDK} -workspace PINRemoteImage.xcworkspace -scheme PINRemoteImage \
	CODE_SIGNING_REQUIRED=NO \
	CLANG_ANALYZER_OUTPUT=plist-html \
	CLANG_ANALYZER_OUTPUT_DIR="$(shell pwd)/clang" | xcpretty
	if [[ -n `find $(shell pwd)/clang -name "*.html"` ]] ; then rm -rf `pwd`/clang; exit 1; fi
	rm -rf $(shell pwd)/clang
	
test:
	xcodebuild clean test -destination ${PLATFORM} -sdk ${SDK} -workspace PINRemoteImage.xcworkspace -scheme PINRemoteImage \
	CODE_SIGNING_REQUIRED=NO | xcpretty
	
carthage:
	if [ ${XCODE_MAJOR_VERSION} -gt 11 ] ; then \
 		echo "Carthage no longer works in Xcode 12 https://github.com/Carthage/Carthage/blob/master/Documentation/Xcode12Workaround.md"; \
 		exit 1; \
 	fi
	carthage update --no-use-binaries --no-build
	carthage build --no-use-binaries --no-skip-current

webp:
	carthage update --no-use-binaries --no-build
	cd webp && ../Carthage/Checkouts/libwebp/iosbuild.sh

spm:
	swift build
	
all: carthage test cocoapods analyze spm