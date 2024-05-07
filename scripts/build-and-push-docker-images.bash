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

declare -a docker_tags=()

# regex to parse semver 2.0.0, with pre-release and build number
git_branch_or_tag_name=${GITHUB_REF_NAME:-$(git rev-parse --abbrev-ref HEAD)}

if [[ -z $git_branch_or_tag_name ]]; then
  git_branch_or_tag_name=$(git rev-parse --abbrev-ref HEAD)
fi

push_platforms="$current_platform"
if [[ ${git_branch_or_tag_name:-} =~ ^v?(([0-9]+)\.([0-9]+)\.([0-9]+)(-([a-zA-Z0-9-]+))?(\+([a-zA-Z0-9\.-]+))?)$ ]]; then
  major="${BASH_REMATCH[2]}"
  minor="${BASH_REMATCH[3]}"
  patch="${BASH_REMATCH[4]}"

  if [ -z "${BASH_REMATCH[5]}" ]; then
    # not a pre-release, tag latest
    main_tag="latest"
    docker_tags+=("latest" "v${major}" "v${major}.${minor}" "v${major}.${minor}.${patch}")
  else
    # pre-release, just use the tag
    main_tag="git--${git_branch_or_tag_name//[^a-zA-Z0-9]/-}"
    docker_tags+=("$main_tag")
  fi
  # tag so push to all platforms
  push_platforms="linux/amd64,linux/arm64"
else
  # not a semantic version, just use the branch or tag
  main_tag="git--${git_branch_or_tag_name//[^a-zA-Z0-9]/-}"
  docker_tags+=("$main_tag")
fi

# build for the current platform
docker buildx build \
  --platform="$current_platform" \
  --progress=plain \
  --cache-from=elijahru/lintball \
  --cache-from="elijahru/lintball:${main_tag}" \
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

# # Build the test image
# docker buildx build \
#   --platform="$platforms_csv" \
#   --progress=plain \
#   --cache-from=elijahru/lintball \
#   --cache-from="elijahru/lintball:${main_tag}" \
#   --cache-from=elijahru/lintball:test \
#   --tag=elijahru/lintball:test \
#   --target=lintball-test \
#   --load \
#   .

# # Run the tests
# for platform in "${platforms[@]}"; do
#   docker run \
#     --platform "$platform" \
#     --volume "${LINTBALL_WORKSPACE:-.}:/workspace:cached" \
#     --volume ./bin:/lintball/bin:cached \
#     --volume ./configs:/lintball/configs:cached \
#     --volume ./lib:/lintball/lib:cached \
#     --volume ./scripts:/lintball/scripts:cached \
#     --volume ./test:/lintball/test:cached \
#     elijahru/lintball:test \
#     npm run test
# done

echo "Pushing tags: ${docker_tags@Q}"
echo "Pushing platforms: ${push_platforms}"

for tag in "${docker_tags[@]}"; do
  # build for the current platform
  docker buildx build \
    --platform="$push_platforms" \
    --progress=plain \
    --cache-from=elijahru/lintball \
    --cache-from="elijahru/lintball:${main_tag}" \
    --tag="elijahru/lintball:${tag}" \
    --target=lintball-latest \
    --push \
    .
done
