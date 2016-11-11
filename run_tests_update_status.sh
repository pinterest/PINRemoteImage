#!/usr/bin/env bash
set -eo pipefail

trapped="false"
function trap_handler() {
    if [[ "$trapped" = "false" ]]; then
        echo "Tests failed, updating status to failure"
    fi
    trapped="true"
}
trap trap_handler INT TERM EXIT

./build.sh all

echo "All tests succeeded, updating status to success"
trap - EXIT
exit 0