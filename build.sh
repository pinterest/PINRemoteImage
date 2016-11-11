#!/usr/bin/env bash
set -eo pipefail

# **** Update me when new Xcode versions are released! ****
PLATFORM="platform=iOS Simulator,OS=10.1,name=iPhone 7"
SDK="iphonesimulator10.1"

MODE="$1"

if [[ -z "$MODE" ]] ; then
    MODE="all"
fi

if [[ "$MODE" = "lint" || "$MODE" = "all" ]] ; then
    pod lib lint --allow-warnings
fi

if [[ "$MODE" = "tests" || "$MODE" = "all" ]] ; then
    xcodebuild clean test -destination "$PLATFORM" -sdk "$SDK" -workspace Example/PINRemoteImage.xcworkspace -scheme PINRemoteImage ONLY_ACTIVE_ARCH=NO CODE_SIGNING_REQUIRED=NO | xcpretty -t; test ${PIPESTATUS[0]} -eq 0
fi