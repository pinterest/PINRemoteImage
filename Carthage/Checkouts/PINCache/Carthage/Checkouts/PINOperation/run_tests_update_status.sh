#!/usr/bin/env bash
set -eo pipefail

UPDATE_STATUS_PATH=$1
BUILDKITE_PULL_REQUEST=$2
BUILDKITE_BUILD_URL=$3

function updateStatus() {
  if [ "${BUILDKITE_PULL_REQUEST}" != "false" ] ; then
    ${UPDATE_STATUS_PATH} "pinterest" "PINOperation" ${BUILDKITE_PULL_REQUEST} "$1" ${BUILDKITE_BUILD_URL} "$2" "CI/Pinterest"
  fi
}

if [[ -z "${UPDATE_STATUS_PATH}" || -z "${BUILDKITE_PULL_REQUEST}" || -z "${BUILDKITE_BUILD_URL}" ]] ; then
    echo "Update status path (${UPDATE_STATUS_PATH}), pull request (${BUILDKITE_BUILD_URL}) or build url (${BUILDKITE_PULL_REQUEST}) unset."
    trap - EXIT
    exit 255
fi

trapped="false"
function trap_handler() {
    if [[ "$trapped" = "false" ]]; then
        updateStatus failure "Tests failed…"
        echo "Tests failed, updated status to failure"
    fi
    trapped="true"
}
trap trap_handler INT TERM EXIT

updateStatus pending "Starting build…"

make all

updateStatus success "Tests passed"

echo "All tests succeeded, updated status to success"
trap - EXIT
exit 0