# shellcheck disable=SC2034

## Expected lintballrc_version in config files
LINTBALLRC_VERSION="2"
export LINTBALLRC_VERSION

## Global lintball config - modified by config files
declare -a LINTBALL_CHECK_ARGS_AUTOFLAKE=()
declare -a LINTBALL_CHECK_ARGS_AUTOPEP8=()
declare -a LINTBALL_CHECK_ARGS_BLACK=()
declare -a LINTBALL_CHECK_ARGS_DOCFORMATTER=()
declare -a LINTBALL_CHECK_ARGS_ESLINT=()
declare -a LINTBALL_CHECK_ARGS_ISORT=()
declare -a LINTBALL_CHECK_ARGS_PRETTIER=()
declare -a LINTBALL_CHECK_ARGS_PYLINT=()
declare -a LINTBALL_CHECK_ARGS_SHELLCHECK=()
declare -a LINTBALL_CHECK_ARGS_SHFMT=()
declare -a LINTBALL_CHECK_ARGS_YAMLLINT=()

declare -a LINTBALL_WRITE_ARGS_AUTOFLAKE=()
declare -a LINTBALL_WRITE_ARGS_AUTOPEP8=()
declare -a LINTBALL_WRITE_ARGS_BLACK=()
declare -a LINTBALL_WRITE_ARGS_DOCFORMATTER=()
declare -a LINTBALL_WRITE_ARGS_ESLINT=()
declare -a LINTBALL_WRITE_ARGS_ISORT=()
declare -a LINTBALL_WRITE_ARGS_PRETTIER=()
declare -a LINTBALL_WRITE_ARGS_PYLINT=()
declare -a LINTBALL_WRITE_ARGS_SHELLCHECK=()
declare -a LINTBALL_WRITE_ARGS_SHFMT=()
declare -a LINTBALL_WRITE_ARGS_YAMLLINT=()

declare -a LINTBALL_IGNORE_GLOBS=()
declare -a LINTBALL_FIND_ARGS=()

# shellcheck disable=SC2034
declare -a LINTBALL_HANDLED_EXTENSIONS=(
  bash bats cjs css graphql html jade js json jsx ksh
  md mdx mksh pug pxd pxi py pyi pyx scss sh ts tsx
  xml yaml yml)

declare -a LINTBALL_ALL_TOOLS=(
  autoflake autopep8 black docformatter eslint isort
  prettier pylint shellcheck shfmt yamllint)

# Used by some tools to determine whether to install binaries or compile source
LIBC_TYPE="$(if command -v clang 2>&1 >/dev/null; then
  echo "clang"
elif ldd /bin/ls | grep musl 2>&1 >/dev/null; then
  echo "musl"
else
  echo "gnu"
fi)"
export LIBC_TYPE

## ASDF config
ASDF_VERSION=v0.14.1
export ASDF_VERSION
ASDF_CONFIG_FILE="${LINTBALL_DIR}/configs/asdfrc"
export ASDF_CONFIG_FILE
ASDF_DEFAULT_TOOL_VERSIONS_FILENAME="no-tool-versions"
export ASDF_DEFAULT_TOOL_VERSIONS_FILENAME
ASDF_DIR="${LINTBALL_DIR}/tools/asdf"
export ASDF_DIR
ASDF_DATA_DIR="${LINTBALL_DIR}/tools/asdf"
export ASDF_DATA_DIR

## ASDF tool versions
ASDF_NODEJS_VERSION=22.11.0
export ASDF_NODEJS_VERSION
ASDF_SHFMT_VERSION=3.10.0
export ASDF_SHFMT_VERSION
ASDF_SHELLCHECK_VERSION=0.10.0
export ASDF_SHELLCHECK_VERSION
ASDF_PYTHON_VERSION=3.13.0
export ASDF_PYTHON_VERSION

## ASDF tool config
if [[ ${LIBC_TYPE} == "musl" ]]; then
  # binary nodejs doesn't run on alpine / musl
  # see https://github.com/asdf-vm/asdf-nodejs/issues/190
  ASDF_NODEJS_FORCE_COMPILE=1
  export ASDF_NODEJS_FORCE_COMPILE
fi

## Setup PATH to find installed tools
PATH="${LINTBALL_DIR}/tools/node_modules/.bin:${PATH}"
PATH="${LINTBALL_DIR}/tools/asdf/shims:${PATH}"
PATH="${LINTBALL_DIR}/tools/asdf/bin:${PATH}"
PATH="${LINTBALL_DIR}/tools/bin:${PATH}"
export PATH
