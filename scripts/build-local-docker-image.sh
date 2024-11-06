#!/usr/bin/env bash

set -eu

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
  $progress_arg \
  "${cache_from_args[@]}" \
  --tag=lintball:local \
  --file="${LINTBALL_DIR}/Dockerfile.slim" \
  "${LINTBALL_DIR}"
