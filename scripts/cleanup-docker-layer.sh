#!/bin/sh

set -eux

if [ "${IS_DOCKER_BUILD:-}" -eq "1" ]; then
  find /lintball/tools -type d -name '.github' -exec rm -rf {} \; || true
  find /lintball/tools -type f -name 'CHANGELOG*' -exec rm -f {} \; || true
  find /lintball/tools/asdf/installs/python -type d -name '__pycache__' -exec rm -rf {} \; || true
  find /lintball/tools/asdf/installs/python -type f -name '*.pyi' -exec rm -f {} \; || true
  find /lintball/tools/asdf/installs/python -type d -wholename '/lintball/tools/asdf/installs/python/*/lib/python*/test' -exec rm -rf {} \; || true
  find /lintball/tools/asdf/installs/python -type f -wholename '*/site-packages/*/test/*.py' -exec rm -f {} \; || true
  find /lintball/tools/asdf/installs/python -type f -wholename '*/site-packages/*/tests/*.py' -exec rm -f {} \; || true
  find /lintball/tools/node_modules -type d -name 'scripts' -exec rm -rf {} \; || true
  find /lintball/tools/node_modules -type f -name '.eslintrc*' -exec rm -f {} \; || true
  find /lintball/tools/node_modules -type f -name '*.d.ts' -exec rm -f {} \; || true
  find /lintball/tools/node_modules -type f -name '*.js.map' -exec rm -f {} \; || true
  find /lintball/tools/node_modules -type f -name '*.test.js' -exec rm -f {} \; || true
  find /lintball/tools/node_modules -type f -name 'test.js' -exec rm -f {} \; || true
  rm -rf /tmp/* || true
  rm -rf /usr/share/doc/ || true
  rm -rf /usr/share/locale/ || true
  rm -rf /usr/share/man/ || true
  rm -rf /usr/share/X11/locale/ || true
  rm -rf /var/cache/apt/archives || true
  rm -rf /var/lib/apt/lists/* || true
  rm -rf /var/tmp/* || true
fi
