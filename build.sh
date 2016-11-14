#!/usr/bin/env bash
set -eo pipefail

# **** Update me when new Xcode versions are released! ****
PLATFORM="platform=iOS Simulator,OS=10.1,name=iPhone 7"
SDK="iphonesimulator10.1"

MODE="$1"

function echoHeader() {
    echo ""
    echo ""
    echo $1
    echo ""
}

if [[ -z "$MODE" ]] ; then
    MODE="all"
fi

if [[ "$MODE" = "lint" || "$MODE" = "all" ]] ; then
    echoHeader "Testing CocoaPod configurations"
    pod lib lint --allow-warnings
fi

if [[ "$MODE" = "tests" || "$MODE" = "all" ]] ; then
    echoHeader "Running unit tests"
    xcodebuild clean test -destination "$PLATFORM" -sdk "$SDK" -workspace Example/PINRemoteImage.xcworkspace -scheme PINRemoteImage ONLY_ACTIVE_ARCH=NO CODE_SIGNING_REQUIRED=NO | xcpretty -t; test ${PIPESTATUS[0]} -eq 0
fi

if [[ "$MODE" = "carthage" || "$MODE" = "all" ]] ; then
    echoHeader "Testing Carthage build"
    carthage update
    carthage build --no-skip-current --project-directory PINRemoteImage
fi

echo ""
echo "Finished tests"