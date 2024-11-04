#!/usr/bin/env bash

set -eu

LINTBALL_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)

cd "${LINTBALL_DIR}"

if [[ -n $(command -v jq) ]]; then
  IFS= read -r lintball_version < <(jq -r .version "package.json")
elif [[ -n $(command -v npm) ]]; then
  # shellcheck disable=SC2016
  lintball_version=$(npm -s run env echo '$npm_package_version')
else
  echo >&2
  echo "Could not find jq or npm. Please install one of them." >&2
  exit 1
fi

IFS= read -r lintball_major_version < <(echo "${lintball_version}" | awk -F '.' '{print $1}')

docker build \
  --tag lintball:local \
  --cache-from elijahru/lintball:v"${lintball_major_version}" \
  --file "${LINTBALL_DIR}/Dockerfile" "${LINTBALL_DIR}"
