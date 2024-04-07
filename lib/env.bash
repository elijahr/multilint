# shellcheck disable=SC2034

## Expected lintballrc_version in config files
LINTBALLRC_VERSION="2"
export LINTBALLRC_VERSION

## Global lintball config - modified by config files
declare -a LINTBALL_CHECK_ARGS_AUTOFLAKE=()
declare -a LINTBALL_CHECK_ARGS_AUTOPEP8=()
declare -a LINTBALL_CHECK_ARGS_BLACK=()
declare -a LINTBALL_CHECK_ARGS_CLIPPY=()
declare -a LINTBALL_CHECK_ARGS_DOCFORMATTER=()
declare -a LINTBALL_CHECK_ARGS_ESLINT=()
declare -a LINTBALL_CHECK_ARGS_ISORT=()
declare -a LINTBALL_CHECK_ARGS_NIMPRETTY=()
declare -a LINTBALL_CHECK_ARGS_PRETTIER=()
declare -a LINTBALL_CHECK_ARGS_PYLINT=()
declare -a LINTBALL_CHECK_ARGS_RUBOCOP=()
declare -a LINTBALL_CHECK_ARGS_SHELLCHECK=()
declare -a LINTBALL_CHECK_ARGS_SHFMT=()
declare -a LINTBALL_CHECK_ARGS_STYLUA=()
declare -a LINTBALL_CHECK_ARGS_UNCRUSTIFY=()
declare -a LINTBALL_CHECK_ARGS_YAMLLINT=()

declare -a LINTBALL_WRITE_ARGS_AUTOFLAKE=()
declare -a LINTBALL_WRITE_ARGS_AUTOPEP8=()
declare -a LINTBALL_WRITE_ARGS_BLACK=()
declare -a LINTBALL_WRITE_ARGS_CLIPPY=()
declare -a LINTBALL_WRITE_ARGS_DOCFORMATTER=()
declare -a LINTBALL_WRITE_ARGS_ESLINT=()
declare -a LINTBALL_WRITE_ARGS_ISORT=()
declare -a LINTBALL_WRITE_ARGS_NIMPRETTY=()
declare -a LINTBALL_WRITE_ARGS_PRETTIER=()
declare -a LINTBALL_WRITE_ARGS_PYLINT=()
declare -a LINTBALL_WRITE_ARGS_RUBOCOP=()
declare -a LINTBALL_WRITE_ARGS_SHELLCHECK=()
declare -a LINTBALL_WRITE_ARGS_SHFMT=()
declare -a LINTBALL_WRITE_ARGS_STYLUA=()
declare -a LINTBALL_WRITE_ARGS_UNCRUSTIFY=()
declare -a LINTBALL_WRITE_ARGS_YAMLLINT=()

declare -a LINTBALL_IGNORE_GLOBS=()
declare -a LINTBALL_FIND_ARGS=()

# shellcheck disable=SC2034
declare -a LINTBALL_HANDLED_EXTENSIONS=(
  bash bats c cjs cpp cs css d dash graphql h hpp html jade java js json jsx ksh
  lua m M md mdx mksh mm nim pug pxd pxi py pyi pyx rb rs scss sh toml ts tsx
  xml yaml yml)

declare -a LINTBALL_ALL_TOOLS=(
  autoflake autopep8 black clippy docformatter eslint isort nimpretty
  prettier pylint rubocop shellcheck shfmt stylua uncrustify yamllint)

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
ASDF_VERSION=v0.10.2
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
ASDF_NODEJS_VERSION=20.12.1
export ASDF_NODEJS_VERSION
ASDF_SHFMT_VERSION=3.8.0
export ASDF_SHFMT_VERSION
ASDF_SHELLCHECK_VERSION=0.10.0
export ASDF_SHELLCHECK_VERSION
ASDF_RUST_VERSION=1.77.1
export ASDF_RUST_VERSION
ASDF_PYTHON_VERSION=3.12.2
export ASDF_PYTHON_VERSION
ASDF_NIM_VERSION=ref:version-2-0
export ASDF_NIM_VERSION
ASDF_RUBY_VERSION=3.3.0
export ASDF_RUBY_VERSION

## ASDF tool config
# Allow rustup installation
RUSTUP_INIT_SKIP_PATH_CHECK=yes
export RUSTUP_INIT_SKIP_PATH_CHECK
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
