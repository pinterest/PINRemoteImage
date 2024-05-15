PLATFORM="platform=iOS Simulator,name=iPhone 15"
SDK="iphonesimulator"
SHELL=/bin/bash -o pipefail
XCODE_MAJOR_VERSION=$(shell xcodebuild -version | HEAD -n 1 | sed -E 's/Xcode ([0-9]+).*/\1/')

.PHONY: all cocoapods test analyze carthage spm install_xcbeautify
	
carthage:
	carthage build --no-skip-current --use-xcframeworks

cocoapods:
	pod lib lint

install_xcbeautify:
	if ! command -v xcbeautify &> /dev/null; then brew install xcbeautify; fi

analyze: install_xcbeautify
	xcodebuild clean analyze -destination ${PLATFORM} -sdk ${SDK} -project PINOperation.xcodeproj -scheme PINOperation \
	ONLY_ACTIVE_ARCH=NO \
	CODE_SIGNING_REQUIRED=NO \
	CLANG_ANALYZER_OUTPUT=plist-html \
	CLANG_ANALYZER_OUTPUT_DIR="$(shell pwd)/clang" | xcbeautify
	if [[ -n `find $(shell pwd)/clang -name "*.html"` ]] ; then rm -rf `pwd`/clang; exit 1; fi
	rm -rf $(shell pwd)/clang
	
test: install_xcbeautify
	# TODO: Fix data races and enable thread sanitizer with '-enableThreadSanitizer YES'
	xcodebuild clean test -destination ${PLATFORM} -sdk ${SDK} -project PINOperation.xcodeproj -scheme PINOperation \
	ONLY_ACTIVE_ARCH=NO \
	CODE_SIGNING_REQUIRED=NO | xcbeautify

spm:
	# TODO: Fix data races and enable thread sanitizer with '--sanitize thread'
	swift test

release-major:

release-minor:

release-patch:
	

all: carthage cocoapods test analyze spm
