PLATFORM="platform=iOS Simulator,name=iPhone 8"
SDK="iphonesimulator"
SHELL=/bin/bash -o pipefail

.PHONY: all cocoapods test analyze carthage spm
	
carthage:
	carthage build --no-skip-current

cocoapods:
	pod lib lint

analyze:
	xcodebuild clean analyze -destination ${PLATFORM} -sdk ${SDK} -project PINOperation.xcodeproj -scheme PINOperation \
	ONLY_ACTIVE_ARCH=NO \
	CODE_SIGNING_REQUIRED=NO \
	CLANG_ANALYZER_OUTPUT=plist-html \
	CLANG_ANALYZER_OUTPUT_DIR="$(shell pwd)/clang" | xcpretty
	if [[ -n `find $(shell pwd)/clang -name "*.html"` ]] ; then rm -rf `pwd`/clang; exit 1; fi
	rm -rf $(shell pwd)/clang
	
test:
	xcodebuild clean test -destination ${PLATFORM} -sdk ${SDK} -project PINOperation.xcodeproj -scheme PINOperation \
	ONLY_ACTIVE_ARCH=NO \
	CODE_SIGNING_REQUIRED=NO | xcpretty

spm:
# For now just check whether we can assemble it
# TODO: replace it with "swift test --enable-test-discovery --sanitize=thread" when swiftPM resource-related bug would be fixed.
# https://bugs.swift.org/browse/SR-13560
	swift build

all: carthage cocoapods test analyze spm