#!/usr/bin/env bash

set -eu

LINTBALL_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)

apt update
apt install -y jq git procps
source "${LINTBALL_DIR}"/lib/env.bash
# shellcheck disable=SC1091
source "${LINTBALL_DIR}"/tools/asdf/asdf.sh
cd "${LINTBALL_DIR}"/tools
asdf reshim
npm ci --include=dev
npm cache clean --force
asdf reshim
exec npm run test -- "$@"
