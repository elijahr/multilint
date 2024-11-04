#!/usr/bin/env bash

set -eu

LINTBALL_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)

"${LINTBALL_DIR}"/scripts/build-local-docker-image.sh

exec docker run \
  -v "${LINTBALL_DIR}/.git:/lintball/.git" \
  -v "${LINTBALL_DIR}/test:/lintball/test" \
  lintball:local bash /lintball/scripts/run-tests-internal.sh "$@"
