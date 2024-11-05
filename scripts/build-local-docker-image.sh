#!/usr/bin/env bash

set -eu

LINTBALL_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)

cd "${LINTBALL_DIR}"

source ./scripts/docker-tags.bash

# build for the current platform with cache from all tags
cache_from_args=(--cache-from=elijahru/lintball:git--devel)
for tag in "${docker_tags[@]}"; do
  cache_from_args+=(--cache-from="elijahru/lintball:${tag}")
done

# Remove duplicates from cache_from_args
# shellcheck disable=SC2207
cache_from_args=($(printf "%s\n" "${cache_from_args[@]}" | awk '!seen[$0]++'))

docker build \
  --tag lintball:local \
  "${cache_from_args[@]}" \
  --file "${LINTBALL_DIR}/Dockerfile" "${LINTBALL_DIR}"
