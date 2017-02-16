PLATFORM="platform=iOS Simulator,OS=10.2,name=iPhone 7"
SDK="iphonesimulator10.2"
SHELL=/bin/bash -o pipefail

.PHONY: all lint test carthage analyze

lint:
	pod lib lint

analyze:
	xcodebuild clean analyze -destination ${PLATFORM} -sdk ${SDK} -project PINCache.xcodeproj -scheme PINCache \
	ONLY_ACTIVE_ARCH=NO \
	CODE_SIGNING_REQUIRED=NO \
	CLANG_ANALYZER_OUTPUT=plist-html \
	CLANG_ANALYZER_OUTPUT_DIR="$(shell pwd)/clang" | xcpretty
	if [[ -n `find $(shell pwd)/clang -name "*.html"` ]] ; then rm -rf `pwd`/clang; exit 1; fi
	rm -rf $(shell pwd)/clang

test:
	xcodebuild clean test -destination ${PLATFORM} -sdk ${SDK} -project PINCache.xcodeproj -scheme PINCache \
	ONLY_ACTIVE_ARCH=NO \
	CODE_SIGNING_REQUIRED=NO | xcpretty

carthage:
	carthage update --no-use-binaries --no-build
	carthage build --no-skip-current

all: carthage lint test analyze