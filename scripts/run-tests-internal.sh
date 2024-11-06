#!/usr/bin/env bash

set -eu

LINTBALL_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)

source "${LINTBALL_DIR}"/lib/env.bash

if [[ $USE_ASDF == "true" ]]; then
  # shellcheck disable=SC1091
  source "${LINTBALL_DIR}"/tools/asdf/asdf.sh
fi

cd "${LINTBALL_DIR}"/tools

if [[ $USE_ASDF == "true" ]]; then
  asdf reshim
fi

npm ci --include=dev
npm cache clean --force

if [[ $USE_ASDF == "true" ]]; then
  asdf reshim
fi

exec npm run test -- "$@"
