#!/usr/bin/env bats

load ../tools/node_modules/bats-support/load
load ../tools/node_modules/bats-assert/load
load ./lib/test_utils

setup() {
  setup_test
}

teardown() {
  teardown_test
}

@test 'lintball install-githooks without --path' {
  run lintball install-githooks --no # 3>&-
  assert_success
  assert_equal "$(safe_git --git-dir="${BATS_TEST_TMPDIR}/.git" config --local core.hooksPath)" "${BATS_TEST_TMPDIR}/.githooks"
  assert [ -x "${BATS_TEST_TMPDIR}/.githooks/pre-commit" ]
}

@test 'lintball install-githooks with --path' {
  IFS= read -r tmp < <(mktemp -d)
  safe_git init "${tmp}"
  run lintball install-githooks --no --path "${tmp}" # 3>&-
  assert_success
  assert_equal "$(safe_git --git-dir="${tmp}/.git" config --local core.hooksPath)" "${tmp}/.githooks"
  assert [ -x "${tmp}/.githooks/pre-commit" ]
  rm -rf "${tmp}"
}

@test 'lintball install-githooks already configured' {
  run lintball install-githooks --no # 3>&-
  assert_success
  run lintball install-githooks --no # 3>&-
  assert_failure
}

@test 'lintball install-githooks does not cause shellcheck errors' {
  run lintball install-githooks --no # 3>&-
  run lintball check .githooks # 3>&-
  assert_success
}
