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

@test 'lintball check' {
  # Remove all but two files - just an optimization
  find . -type f \( -not -name 'a.json' -and -not -name 'a.yml' \) -delete
  run lintball check # 3>&-
  assert_failure
  assert_line "a.json"
  assert_line "a.yml"
  assert [ "$(echo "${output}" | grep -cF " ↳ prettier...........................❌" -c)" -eq 2 ]
  assert [ "$(echo "${output}" | grep -cF " ↳ yamllint...........................❌" -c)" -eq 1 ]
  run lintball fix # 3>&-
  assert_success
  assert [ "$(echo "${output}" | grep -cF " ↳ prettier...........................wrote" -c)" -eq 2 ]
  assert [ "$(echo "${output}" | grep -cF " ↳ yamllint...........................ok" -c)" -eq 1 ]
  run lintball check # 3>&-
  assert_success
  assert [ "$(echo "${output}" | grep -cF " ↳ prettier...........................ok" -c)" -eq 2 ]
  assert [ "$(echo "${output}" | grep -cF " ↳ yamllint...........................ok" -c)" -eq 1 ]
}

@test 'lintball check --since HEAD~1' {
  safe_git add .
  safe_git reset a.html a.xml a.yml
  safe_git commit -m "commit 1"
  safe_git add a.html
  safe_git commit -m "commit 2"
  safe_git rm a.md
  safe_git commit -m "commit 3"
  safe_git add a.yml
  run lintball check --since HEAD~2 # 3>&-
  assert_failure
  # previously committed
  assert_line "a.html"
  # untracked
  assert_line "a.xml"
  # staged, never committed
  assert_line "a.yml"
  # deleted
  refute_line "a.md"
  # committed before HEAD~2
  refute_line "a.css"
  run lintball fix --since HEAD~1   # 3>&-
  run lintball check --since HEAD~1 # 3>&-
  assert_success
}

@test 'lintball check # lintball lang=bash' {
  run lintball check "b_bash" # 3>&-
  assert_failure
  run lintball fix "b_bash"   # 3>&-
  run lintball check "b_bash" # 3>&-
  assert_success
}

@test 'lintball check #!/bin/sh' {
  run lintball check "a_sh" # 3>&-
  assert_failure
  run lintball fix "a_sh"   # 3>&-
  run lintball check "a_sh" # 3>&-
  assert_success
}

@test 'lintball check #!/usr/bin/env bash' {
  run lintball check "a_bash" # 3>&-
  assert_failure
  run lintball fix "a_bash"   # 3>&-
  run lintball check "a_bash" # 3>&-
  assert_success
}

@test 'lintball check #!/usr/bin/env deno' {
  run lintball check "b_js" # 3>&-
  assert_failure
  run lintball fix "b_js"   # 3>&-
  run lintball check "b_js" # 3>&-
  assert_success
}

@test 'lintball check #!/usr/bin/env node' {
  run lintball check "a_js" # 3>&-
  assert_failure
  run lintball fix "a_js"   # 3>&-
  run lintball check "a_js" # 3>&-
  assert_success
}

@test 'lintball check #!/usr/bin/env python3' {
  run lintball check "a_py" # 3>&-
  assert_failure
  run lintball fix "a_py"   # 3>&-
  run lintball check "a_py" # 3>&-
  assert_success
}

@test 'lintball check *.bash' {
  run lintball check "a.bash" # 3>&-
  assert_failure
  run lintball fix "a.bash"   # 3>&-
  run lintball check "a.bash" # 3>&-
  assert_success
}

@test 'lintball check *.bats' {
  run lintball check "a.bats" # 3>&-
  assert_failure
  run lintball fix "a.bats"   # 3>&-
  run lintball check "a.bats" # 3>&-
  assert_success
}

@test 'lintball check *.css' {
  run lintball check "a.css" # 3>&-
  assert_failure
  run lintball fix "a.css"   # 3>&-
  run lintball check "a.css" # 3>&-
  assert_success
}

@test 'lintball check *.html' {
  run lintball check "a.html" # 3>&-
  assert_failure
  run lintball fix "a.html"   # 3>&-
  run lintball check "a.html" # 3>&-
  assert_success
}

@test 'lintball check *.js' {
  run lintball check "a.js" # 3>&-
  assert_failure
  run lintball fix "a.js"   # 3>&-
  run lintball check "a.js" # 3>&-
  assert_success
}

@test 'lintball check *.json' {
  run lintball check "a.json" # 3>&-
  assert_failure
  run lintball fix "a.json"   # 3>&-
  run lintball check "a.json" # 3>&-
  assert_success
}

@test 'lintball check *.jsx' {
  run lintball check "a.jsx" # 3>&-
  assert_failure
  run lintball fix "a.jsx"   # 3>&-
  run lintball check "a.jsx" # 3>&-
  assert_success
}

@test 'lintball check *.ksh' {
  run lintball check "a.ksh" # 3>&-
  assert_failure
  run lintball fix "a.ksh"   # 3>&-
  run lintball check "a.ksh" # 3>&-
  assert_success
}

@test 'lintball check *.md' {
  run lintball check "a.md" # 3>&-
  assert_failure
  run lintball fix "a.md"   # 3>&-
  run lintball check "a.md" # 3>&-
  assert_success
}

@test 'lintball check *.mdx' {
  run lintball check "a.mdx" # 3>&-
  assert_failure
  run lintball fix "a.mdx"   # 3>&-
  run lintball check "a.mdx" # 3>&-
  assert_success
}

@test 'lintball check *.mksh' {
  run lintball check "a.mksh" # 3>&-
  assert_failure
  run lintball fix "a.mksh"   # 3>&-
  run lintball check "a.mksh" # 3>&-
  assert_success
}

@test 'lintball check *.pug' {
  run lintball check "a.pug" # 3>&-
  assert_failure
  run lintball fix "a.pug"   # 3>&-
  run lintball check "a.pug" # 3>&-
  assert_success
}

@test 'lintball check *.py' {
  run lintball check "a.py" # 3>&-
  assert_failure
  run lintball fix "a.py"   # 3>&-
  run lintball check "a.py" # 3>&-
  assert_success
}

@test 'lintball check *.pyi' {
  run lintball check "c.pyi" # 3>&-
  assert_failure
  run lintball fix "c.pyi"   # 3>&-
  run lintball check "c.pyi" # 3>&-
  assert_success
}

@test 'lintball check *.pyx' {
  run lintball check "b.pyx" # 3>&-
  assert_failure
  run lintball fix "b.pyx"   # 3>&-
  run lintball check "b.pyx" # 3>&-
  assert_success
}

@test 'lintball check *.scss' {
  run lintball check "a.scss" # 3>&-
  assert_failure
  run lintball fix "a.scss"   # 3>&-
  run lintball check "a.scss" # 3>&-
  assert_success
}

@test 'lintball check *.sh' {
  run lintball check "a.sh" # 3>&-
  assert_failure
  run lintball fix "a.sh"   # 3>&-
  run lintball check "a.sh" # 3>&-
  assert_success
}

@test 'lintball check *.ts' {
  run lintball check "a.ts" # 3>&-
  assert_failure
  run lintball fix "a.ts"   # 3>&-
  run lintball check "a.ts" # 3>&-
  assert_success
}

@test 'lintball check *.tsx' {
  run lintball check "a.tsx" # 3>&-
  assert_failure
  run lintball fix "a.tsx"   # 3>&-
  run lintball check "a.tsx" # 3>&-
  assert_success
}

@test 'lintball check *.xml' {
  run lintball check "a.xml" # 3>&-
  assert_failure
  run lintball fix "a.xml"   # 3>&-
  run lintball check "a.xml" # 3>&-
  assert_success
}

@test 'lintball check *.yml' {
  run lintball check "a.yml" # 3>&-
  assert_failure
  run lintball fix "a.yml"   # 3>&-
  run lintball check "a.yml" # 3>&-
  assert_success
}

@test 'lintball check handles implicit path' {
  mkdir foo
  cd foo
  run lintball check # 3>&-
  assert_success
  assert_line "No handled files found in current directory."
}

@test 'lintball check handles . path' {
  mkdir foo
  cd foo
  run lintball check . # 3>&-
  assert_success
  assert_line "No handled files found in directory '.'."
}

@test 'lintball check handles paths with spaces' {
  mkdir -p "aaa aaa/bbb bbb"
  cp "a.yml" "aaa aaa/bbb bbb/a b.yml"
  run lintball check "aaa aaa/bbb bbb/a b.yml" # 3>&-
  assert_failure
  assert_line "+key: value"
  assert_line "+hello: world"
}

@test 'lintball check package.json' {
  run lintball check "package.json" # 3>&-
  assert_failure
  run lintball fix "package.json"   # 3>&-
  run lintball check "package.json" # 3>&-
  assert_success
}

@test 'lintball check ignored file fails' {
  run lintball check "a.txt" # 3>&-
  assert_success
  assert_line "File not handled: 'a.txt'."
}

@test 'lintball check ignored directory fails' {
  mkdir a_dir
  cp a.yml a_dir/
  run lintball check "a_dir" # 3>&-
  assert_success
  assert_line "No handled files found in directory 'a_dir'."
}

@test 'lintball check ignored file in ignored directory fails' {
  mkdir a_dir
  cp a.txt a_dir/
  run lintball check "a_dir" # 3>&-
  assert_success
  assert_line "No handled files found in directory 'a_dir'."
}

@test 'lintball check handled file in ignored directory fails' {
  mkdir a_dir
  cp a.yml a_dir/
  run lintball check "a_dir/a.yml" # 3>&-
  assert_success
  assert_line "File not handled with current configuration: 'a_dir/a.yml'."
}

@test 'lintball check missing' {
  run lintball check "missing.txt" # 3>&-
  assert_failure
  assert_line "File not found: 'missing.txt'."

  run lintball check "missing1.txt" "missing2.txt" # 3>&-
  assert_failure
  assert_line "File not found: 'missing1.txt'."
  assert_line "File not found: 'missing2.txt'."
}
