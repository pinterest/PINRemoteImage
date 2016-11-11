#!/usr/bin/env bash
set -eo pipefail

if [[ -z "${UPDATE_STATUS_PATH}" || -z "${BUILDKITE_PULL_REQUEST}" || -z "${BUILDKITE_BUILD_URL}" ]] ; then
    echo "Update status path, build url or pull request unset."
    trap - EXIT
    exit 255
fi

trapped="false"
function trap_handler() {
    if [[ "$trapped" = "false" ]]; then
        ${UPDATE_STATUS_PATH} pinterest PINRemoteImage ${BUILDKIT_PULL_REQUEST} failure ${BUILDKITE_BUILD_URL} "Tests failed." "CI/Pinterest"
        echo "Tests failed, updated status to failure"
    fi
    trapped="true"
}
trap trap_handler INT TERM EXIT

./build.sh all

${UPDATE_STATUS_PATH} pinterest PINRemoteImage ${BUILDKIT_PULL_REQUEST} success ${BUILDKITE_BUILD_URL} "Tests passed." "CI/Pinterest"
echo "All tests succeeded, updated status to success"
trap - EXIT
exit 0