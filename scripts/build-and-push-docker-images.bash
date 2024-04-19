#!/usr/bin/env bash

# Script to build, test, and push lintball docker images.
#
# This script can be run locally, or in a GitHub Actions workflow.
# If run in a GitHub Actions workflow and triggered by a git tag such as v1.2.3,
# it will build for all platforms (amd64, arm64) and push `latest` as well as
# specific version tags (`v1`, `v1.2`, `v1.2.3`).
# If run locally or for a feature branch, it will only build for the current
# platform.

set -uexo pipefail

case $(uname -m) in
  x86_64 | amd64)
    platform=linux/amd64
    ;;
  arm64 | aarch64)
    platform=linux/arm64
    ;;
  *)
    echo >&2
    echo "Unsupported architecture: $(uname -m)" >&2
    exit 1
    ;;
esac

# build for the current platform
docker buildx build \
  --platform=$platform \
  --progress=plain \
  --cache-from=elijahru/lintball \
  --tag=elijahru/lintball:latest \
  --target=lintball-latest \
  --load \
  .

# Lint the codebase
export LINTBALL_WORKSPACE="${GITHUB_WORKSPACE:-${PWD}}"

# Sanity check
docker run \
  --volume "${LINTBALL_WORKSPACE:-.}:/workspace:cached" \
  --volume ./bin:/lintball/bin:cached \
  --volume ./configs:/lintball/configs:cached \
  --volume ./lib:/lintball/lib:cached \
  --volume ./scripts:/lintball/scripts:cached \
  --volume ./test:/lintball/test:cached \
  elijahru/lintball:latest \
  lintball check

# Build the test image
docker buildx build \
  --platform=$platform \
  --progress=plain \
  --cache-from=elijahru/lintball \
  --tag=elijahru/lintball:test \
  --target=lintball-test \
  --load \
  .

# # Run the tests
# docker run \
#   --volume "${LINTBALL_WORKSPACE:-.}:/workspace:cached" \
#   --volume ./bin:/lintball/bin:cached \
#   --volume ./configs:/lintball/configs:cached \
#   --volume ./lib:/lintball/lib:cached \
#   --volume ./scripts:/lintball/scripts:cached \
#   --volume ./test:/lintball/test:cached \
#   elijahru/lintball:test \
#   npm run test

declare -a tags=()

# regex to parse semver 2.0.0, with pre-release and build number
if [[ ${GITHUB_REF_NAME:-} =~ ^v?(([0-9]+)\.([0-9]+)\.([0-9]+)(-([a-zA-Z0-9-]+))?(\+([a-zA-Z0-9\.-]+))?)$ ]]; then
  major="${BASH_REMATCH[2]}"
  minor="${BASH_REMATCH[3]}"
  patch="${BASH_REMATCH[4]}"

  if [ -z "${BASH_REMATCH[5]}" ]; then
    # not a pre-release, tag latest
    tags+=("latest" "v${major}" "v${major}.${minor}" "v${major}.${minor}.${patch}")
  else
    # pre-release, just use the tag
    tags+=("${GITHUB_REF_NAME//[^a-zA-Z0-9]/-}")
  fi
  push_platforms="linux/amd64,linux/arm64"
else
  # not a semantic version, just use the branch or tag
  tags+=("${GITHUB_REF_NAME//[^a-zA-Z0-9]/-}")
  # only push for the current platform; speeds up future builds on this branch
  push_platforms="${platform}"
fi

echo "Pushing tags ${tags@Q}"
echo "Pushing platforms ${push_platforms@Q}"

# for tag in "${tags[@]}"; do
#   # build for the current platform
#   docker buildx build \
#     --platform="${push_platforms}" \
#     --progress=plain \
#     --cache-from=elijahru/lintball \
#     --tag="elijahru/lintball:${tag}" \
#     --target=lintball-latest \
#     --push \
#     .
# done
