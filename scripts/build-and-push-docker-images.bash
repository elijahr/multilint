#!/usr/bin/env bash

# Script to build, test, and push lintball docker images.
#
# This script can be run locally, or in a GitHub Actions workflow.
# If run in a GitHub Actions workflow and triggered by a git tag such as v1.2.3,
# it will build for all platforms (amd64, arm64) and push `latest` as well as
# specific version tags (`v1`, `v1.2`, `v1.2.3`).
# If run locally or for a feature branch, it will only build for the current
# platform.

set -ue

LINTBALL_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)

cd "${LINTBALL_DIR}"

source ./scripts/docker-tags.bash

if [ "${GITHUB_ACTIONS:-}" = "true" ]; then
  progress_arg="--progress=plain"
else
  progress_arg=""
fi

set -x
exec docker buildx build \
  --platform=linux/amd64,linux/arm64 \
  $progress_arg \
  --cache-from=elijahru/lintball \
  "${cache_from_args[@]}" \
  "${tag_args[@]}" \
  --push \
  --file="${LINTBALL_DIR}/Dockerfile.slim" \
  "${LINTBALL_DIR}"
