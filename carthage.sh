
#!/usr/bin/env bash

# ISSUE: https://github.com/Carthage/Carthage/issues/3019
# CREDITS: https://github.com/Carthage/Carthage/issues/3019#issuecomment-734415287
# carthage.sh
# Usage example: ./carthage.sh build --platform iOS

set -euo pipefail

xcconfig=$(mktemp /tmp/static.xcconfig.XXXXXX)
trap 'rm -f "$xcconfig"' INT TERM HUP EXIT

# For Xcode 12 make sure EXCLUDED_ARCHS is set to arm architectures otherwise
# the build will fail on lipo due to duplicate architectures.
for simulator in iphonesimulator appletvsimulator; do
    echo "EXCLUDED_ARCHS__EFFECTIVE_PLATFORM_SUFFIX_${simulator}__NATIVE_ARCH_64_BIT_x86_64__XCODE_1200 = arm64 arm64e armv7 armv7s armv6 armv8" >> $xcconfig
done
echo 'EXCLUDED_ARCHS = $(inherited) $(EXCLUDED_ARCHS__EFFECTIVE_PLATFORM_SUFFIX_$(PLATFORM_NAME)__NATIVE_ARCH_64_BIT_$(NATIVE_ARCH_64_BIT)__XCODE_$(XCODE_VERSION_MAJOR))' >> $xcconfig

export XCODE_XCCONFIG_FILE="$xcconfig"
cat $XCODE_XCCONFIG_FILE
carthage "$@"
