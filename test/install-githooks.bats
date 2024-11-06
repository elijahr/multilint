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
  assert_line "Copied ${LINTBALL_DIR}/scripts/githooks/pre-commit → ${BATS_TEST_TMPDIR}/.githooks/pre-commit"
  assert_line "Set git hooks path → .githooks"
  assert_equal "$(safe_git --git-dir="${BATS_TEST_TMPDIR}/.git" config --local core.hooksPath)" ".githooks"
  assert [ -f "${BATS_TEST_TMPDIR}/.githooks/pre-commit" ]
  assert [ -f "${BATS_TEST_TMPDIR}/.lintball-version" ]
  lintball_version=$(cat "${BATS_TEST_TMPDIR}/.lintball-version")
  expected_lintball_version=$(jq --raw-output ".version" <"${LINTBALL_DIR}/package.json")
  assert_equal "${lintball_version}" "${expected_lintball_version}"
}

@test 'lintball install-githooks with --path' {
  IFS= read -r tmp < <(mktemp -d)
  safe_git init "${tmp}"
  run lintball install-githooks --no --path "${tmp}" # 3>&-
  assert_success
  assert_line "Copied ${LINTBALL_DIR}/scripts/githooks/pre-commit → ${tmp}/.githooks/pre-commit"
  assert_line "Set git hooks path → .githooks"
  assert_equal "$(safe_git --git-dir="${tmp}/.git" config --local core.hooksPath)" ".githooks"
  assert [ -f "${tmp}/.githooks/pre-commit" ]
  assert [ -f "${tmp}/.lintball-version" ]
  lintball_version=$(cat "${tmp}/.lintball-version")
  expected_lintball_version=$(jq --raw-output ".version" <"${LINTBALL_DIR}/package.json")
  assert_equal "${lintball_version}" "${expected_lintball_version}"
  rm -rf "${tmp}"
}

@test 'lintball install-githooks already configured' {
  run lintball install-githooks --no # 3>&-
  assert_success
  assert_line "Copied ${LINTBALL_DIR}/scripts/githooks/pre-commit → ${BATS_TEST_TMPDIR}/.githooks/pre-commit"
  assert_line "Set git hooks path → .githooks"

  run lintball install-githooks --no # 3>&-
  assert_failure
  assert_line "Cancelled because --yes not passed and [Y] not selected."

  run lintball install-githooks --yes # 3>&-
  assert_success
  assert_line "Copied ${LINTBALL_DIR}/scripts/githooks/pre-commit → ${BATS_TEST_TMPDIR}/.githooks/pre-commit"
  assert_line "Set git hooks path → .githooks"
}

@test 'lintball install-githooks does not cause shellcheck errors' {
  run lintball install-githooks --no # 3>&-
  run lintball check .githooks       # 3>&-
  assert_success
}
