PLATFORM="platform=iOS Simulator,name=iPhone 7"
SDK="iphonesimulator"
SHELL=/bin/bash -o pipefail

.PHONY: all lint test analyze carthage
	
carthage:
	carthage build --no-skip-current

lint:
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

all: carthage lint test analyze