#!/bin/sh

set -eux

if [ "${IS_DOCKER_BUILD:-}" -eq "1" ]; then
  find /lintball/tools -type d -name '.github' -exec rm -f {} \;
  find /lintball/tools -type f -name 'CHANGELOG*' -exec rm -f {} \;
  find /lintball/tools/asdf/installs/python -type d -name '__pycache__' -exec rm -f {} \;
  find /lintball/tools/asdf/installs/python -type d -name '*.pyi' -exec rm -f {} \;
  find /lintball/tools/asdf/installs/python -type d -wholename '/lintball/tools/asdf/installs/python/*/lib/python*/test' -exec rm -f {} \;
  find /lintball/tools/asdf/installs/python -type f -wholename '*/site-packages/*/test/*.py' -exec rm -f {} \;
  find /lintball/tools/asdf/installs/python -type f -wholename '*/site-packages/*/tests/*.py' -exec rm -f {} \;
  find /lintball/tools/node_modules -type d -name 'scripts' -exec rm -f {} \;
  find /lintball/tools/node_modules -type f -name '.eslintrc*' -exec rm -f {} \;
  find /lintball/tools/node_modules -type f -name '*.d.ts' -exec rm -f {} \;
  find /lintball/tools/node_modules -type f -name '*.js.map' -exec rm -f {} \;
  find /lintball/tools/node_modules -type f -name '*.test.js' -exec rm -f {} \;
  find /lintball/tools/node_modules -type f -name 'test.js' -exec rm -f {} \;
  rm -rf /tmp/*
  rm -rf /usr/share/doc/
  rm -rf /usr/share/locale/
  rm -rf /usr/share/man/
  rm -rf /usr/share/X11/locale/
  rm -rf /var/cache/apt/archives
  rm -rf /var/lib/apt/lists/*
  rm -rf /var/tmp/*
fi
