#!/usr/bin/env sh

# Have to specify destination because http://www.openradar.me/23857648
xcodebuild ONLY_ACTIVE_ARCH=NO -project tests/PINOperation.xcodeproj -scheme PINOperationTests -sdk iphonesimulator  -destination 'platform=iOS Simulator,name=iPhone 6,OS=latest' clean build test
