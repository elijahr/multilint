#!/usr/bin/env bats

load ../tools/node_modules/bats-support/load
load ../tools/node_modules/bats-assert/load
load ./lib/test_utils

setup() {
  setup_test
  # optimization, only fix a few arbitrary files
  find . \
    -type f \
    -not \( -path "*/.git/*" \) \
    -not -name '.gitignore' \
    -not -name 'a.md' \
    -not -name 'a.txt' \
    -not -name 'a.yml' \
    -not -name '.lintballrc.json' \
    -delete
  safe_git add .gitignore
  safe_git commit -m "Initial commit"
}

teardown() {
  teardown_test
}

@test 'pre-commit adds fixed code to git index' {
  safe_git add .
  run "${LINTBALL_DIR}/bin/lintball" pre-commit
  assert_success
  expected="$(
    cat <<EOF
.lintballrc.json
a.md
a.txt
a.yml
EOF
  )"
  # Everything is staged in index
  assert_equal "$(safe_git diff --name-only --cached | sort)" "${expected}"
  # Nothing is partially staged
  assert_equal "$(safe_git diff --name-only)" ""
}

@test 'pre-commit does not interfere with delete-only commits' {
  safe_git add .
  safe_git commit -m "commit 1"
  safe_git rm a.md
  run "${LINTBALL_DIR}/bin/lintball" pre-commit
  assert_success
  assert_line "No fully staged files, nothing to do."
  assert [ ! -f "a.md" ]
}

@test 'pre-commit does not fix ignored files' {
  mkdir -p a_dir
  cp a.md a_dir/
  safe_git add a.md a_dir
  run "${LINTBALL_DIR}/bin/lintball" pre-commit
  assert_success
  expected="$(
    cat <<EOF
| aaaa | bbbbbb |  cc |
| :--- | :----: | --: |
| a    |   b    |   c |
EOF
  )"
  assert_equal "$(cat "a.md")" "${expected}"
  assert_not_equal "$(cat a_dir/a.md)" "${expected}"
}

@test 'pre-commit fixes code' {
  safe_git add a.md
  run "${LINTBALL_DIR}/bin/lintball" pre-commit
  assert_success
  expected="$(
    cat <<EOF
| aaaa | bbbbbb |  cc |
| :--- | :----: | --: |
| a    |   b    |   c |
EOF
  )"
  assert_equal "$(cat "a.md")" "${expected}"
}

@test 'pre-commit handles paths with spaces' {
  mkdir -p "aaa aaa/bbb bbb"
  mv "a.yml" "aaa aaa/bbb bbb/a b.yml"
  safe_git add .
  run "${LINTBALL_DIR}/bin/lintball" pre-commit
  assert_success
  expected="$(
    cat <<EOF
.lintballrc.json
a.md
a.txt
aaa aaa/bbb bbb/a b.yml
EOF
  )"
  # Everything is staged in index
  assert_equal "$(safe_git diff --name-only --cached | sort)" "${expected}"
  # Nothing is partially staged
  assert_equal "$(safe_git diff --name-only)" ""
  # file was actually fixed
  expected="$(
    cat <<EOF
key: value
hello: world
EOF
  )"
  assert_equal "$(cat "aaa aaa/bbb bbb/a b.yml")" "${expected}"
}
