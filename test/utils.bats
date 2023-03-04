load ../tools/node_modules/bats-support/load
load ../tools/node_modules/bats-assert/load
load ../lib/utils.bash
load ./lib/test_utils.bash

setup() {
  PROJECT_DIR="$(
    cd "$(dirname "${BATS_TEST_DIRNAME}")/.." || exit
    pwd
  )"
  export PROJECT_DIR

  LINTBALL_DIR="${PROJECT_DIR}"
  export LINTBALL_DIR

  ORIGINAL_PATH="${ORIGINAL_PATH:-${PATH}}"
  export ORIGINAL_PATH

  PATH="${LINTBALL_DIR}/bin:${PATH}"
  export PATH
  DIR="$(mktemp -d)"
  export DIR
  cd "${DIR}" || return $?
}

teardown() {
  rm -rf "${DIR}"
  PATH="${ORIGINAL_PATH}"
  export PATH
}

@test "generate_find_cmd" {
  run generate_find_cmd
  assert_success
  assert_output "'find' '.' '-type' 'f' '-print'"

  run generate_find_cmd " "
  assert_success
  assert_output "'find' '.' '-type' 'f' '-print'"

  run generate_find_cmd " " " " " "
  assert_success
  assert_output "'find' '.' '-type' 'f' '-print'"

  LINTBALL_IGNORE_GLOBS=('*.py' '*.rb')
  run generate_find_cmd "dir1" "dir2"
  assert_success
  assert_output "'find' './dir1' './dir2' '-type' 'f' '-a' '(' '-not' '-path' '*.py' ')' '-a' '(' '-not' '-path' '*.rb' ')' '-print'"
  # shellcheck disable=SC2034
  LINTBALL_IGNORE_GLOBS=()

  run generate_find_cmd " dir1" "dir2 "
  assert_success
  assert_output "'find' './dir1' './dir2' '-type' 'f' '-print'"
}

@test "config_find" {
  mkdir subdir
  touch subdir/.lintballrc.json
  cd subdir
  run config_find
  assert_success
  assert_output "${DIR}/subdir/.lintballrc.json"

  # find in parent dir
  mv .lintballrc.json ../.lintballrc.json
  run config_find
  assert_success
  assert_output "${DIR}/.lintballrc.json"

  # find symlink
  ln -s "${DIR}/.lintballrc.json" .lintballrc.json
  run config_find
  assert_success
  assert_output "${DIR}/subdir/.lintballrc.json"
  rm .lintballrc.json

  run config_find "path=."
  assert_success
  assert_output "${DIR}/.lintballrc.json"

  run config_find "path="
  assert_failure
  assert_output "Not a valid path arg: "

  cd /tmp
  run config_find "path=${DIR}"
  assert_success
  assert_output "${DIR}/.lintballrc.json"

  run config_find "path=${DIR}/subdir"
  assert_success
  assert_output "${DIR}/.lintballrc.json"

  run config_find "path=${DIR}/subdir2"
  assert_failure
  assert_output "Not a valid path arg: ${DIR}/subdir2"

  ln -s "${DIR}/subdir" "${DIR}/subdir2"
  assert_success
  assert_output "${DIR}/.lintballrc.json"

  cd "${DIR}" || return $?
  rm .lintballrc.json
  run config_find
  assert_failure
  assert_output ""
}

@test "config_load" {
  # required arg
  run config_load
  assert_failure

  # no path
  run config_load "path="
  assert_failure

  # invalid path
  run config_load "path=abc"
  assert_failure

  # valid path
  cp "${PROJECT_DIR}/configs/lintballrc-defaults.json" "${DIR}/.lintballrc.json"
  run config_load "path=${DIR}"
  assert_success
  assert_equal

  # valid path
  cp "${PROJECT_DIR}/configs/lintballrc-defaults.json" ".lintballrc.json"
  run config_load "path=."
  assert_success
}

@test "parse_major_version" {
  version="1.2.3"
  major_version=$(parse_major_version "${version}")
  assert_equal "${major_version}" "1"
}
