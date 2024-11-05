#!/bin/bash

set -ue

PATH="/lintball/bin:$PATH"
export PATH

LINTBALL_DIR="/lintball"
export LINTBALL_DIR

# shellcheck disable=SC1090
source ~/.profile

# disable git uid/gid check
git config --global --add safe.directory /workspace

exec "$@"
