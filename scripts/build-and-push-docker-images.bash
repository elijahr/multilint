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

cd "$(dirname "${BASH_SOURCE[0]}")/.."

case $(uname -m) in
  x86_64 | amd64)
    current_platform="linux/amd64"
    ;;
  arm64 | aarch64)
    current_platform="linux/arm64"
    ;;
  *)
    echo >&2
    echo "Unsupported architecture: $(uname -m)" >&2
    exit 1
    ;;
esac

source ./scripts/docker-tags.bash

git_branch_or_tag_name=${GITHUB_REF_NAME:-$(git rev-parse --abbrev-ref HEAD)}
if [[ ${git_branch_or_tag_name:-} =~ ^v?(([0-9]+)\.([0-9]+)\.([0-9]+)(-([a-zA-Z0-9-]+))?(\+([a-zA-Z0-9\.-]+))?)$ ]]; then
  # git tag, so push to all platforms
  push_platforms="linux/amd64,linux/arm64"
else
  push_platforms="$current_platform"
fi

# build for the current platform with cache from all tags
cache_from_args=(--cache-from=elijahru/lintball:git--devel)
for tag in "${docker_tags[@]}"; do
  cache_from_args+=(--cache-from="elijahru/lintball:${tag}")
done

# Remove duplicates from cache_from_args
# shellcheck disable=SC2207
cache_from_args=($(printf "%s\n" "${cache_from_args[@]}" | awk '!seen[$0]++'))

docker buildx build \
  --platform="$current_platform" \
  --progress=plain \
  --cache-from=elijahru/lintball \
  "${cache_from_args[@]}" \
  --tag="elijahru/lintball:${main_tag}" \
  --target=lintball-latest \
  --load \
  .

# Lint the codebase
export LINTBALL_WORKSPACE="${GITHUB_WORKSPACE:-${PWD}}"

# Sanity check
docker run \
  --platform="$current_platform" \
  --volume="${LINTBALL_WORKSPACE:-.}:/workspace:cached" \
  --volume=./bin:/lintball/bin:cached \
  --volume=./configs:/lintball/configs:cached \
  --volume=./lib:/lintball/lib:cached \
  --volume=./scripts:/lintball/scripts:cached \
  --volume=./test:/lintball/test:cached \
  "elijahru/lintball:${main_tag}" \
  lintball check

echo "Pushing tags: ${docker_tags@Q}"
echo "Pushing platforms: ${push_platforms}"

for tag in "${docker_tags[@]}"; do
  # build for the current platform
  docker buildx build \
    --platform="$push_platforms" \
    --progress=plain \
    --cache-from=elijahru/lintball \
    "${cache_from_args[@]}" \
    --tag="elijahru/lintball:${tag}" \
    --target=lintball-latest \
    --push \
    .
done
