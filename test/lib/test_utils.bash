# shellcheck disable=2164

safe_git() {
  # run git without loading ~/.gitconfig
  HOME=/dev/null git "$@" || return $?
}

setup_test() {
  LINTBALL_DIR="$(
    cd "$(dirname "${BATS_TEST_DIRNAME}")" || exit 1
    pwd
  )"
  export LINTBALL_DIR
  ORIGINAL_PATH="${ORIGINAL_PATH:-${PATH}}"
  export ORIGINAL_PATH

  PATH="${LINTBALL_DIR}/bin:${PATH}"
  export PATH

  rm -r "${BATS_TEST_TMPDIR}"
  cp -r "${LINTBALL_DIR}/test/fixture" "${BATS_TEST_TMPDIR}"
  cp "${LINTBALL_DIR}/.gitignore" "${BATS_TEST_TMPDIR}/"

  cd "${BATS_TEST_TMPDIR}"
  safe_git init --initial-branch=devel .
  safe_git config --local user.name "Bats Test"
  safe_git config --local user.email "test@example.org"
}

teardown_test() {
  unset LINTBALL_DIR
  PATH="${ORIGINAL_PATH}"
  export PATH
}
