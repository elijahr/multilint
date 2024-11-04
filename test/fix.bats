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

@test 'lintball fix' {
  # Remove all but two files - just an optimization
  find . -type f \( -not -name 'a.json' -and -not -name 'a.yml' \) -delete
  run lintball fix # 3>&-
  assert_success
  assert_line "a.json"
  assert_line "a.yml"
  assert [ "$(echo "${output}" | grep -cF " ↳ prettier...........................wrote" -c)" -eq 2 ]
  assert [ "$(echo "${output}" | grep -cF " ↳ yamllint...........................ok" -c)" -eq 1 ]
}

@test 'lintball fix --since HEAD~1' {
  safe_git add .
  safe_git reset a.html a.xml a.yml
  safe_git commit -m "commit 1"
  safe_git add a.html
  safe_git commit -m "commit 2"
  safe_git rm a.md
  safe_git commit -m "commit 3"
  safe_git add a.yml
  run lintball fix --since HEAD~2 # 3>&-
  assert_success
  assert_line "a.html"
  assert_line "a.xml"
  assert_line "a.yml"
  assert [ "$(echo "${output}" | grep -cF " ↳ prettier...........................wrote")" -eq 3 ]
  assert [ "$(echo "${output}" | grep -cF " ↳ yamllint...........................ok")" -eq 1 ]
}

@test 'lintball fix # lintball lang=bash' {
  run lintball fix "b_bash" # 3>&-
  assert_success
  directive="# lintball lang=bash"
  expected="$(
    cat <<EOF
${directive}

a() {
  echo

}

b() {

  echo
}

c=("a" "b" "c")

for var in "\${c[@]}"; do
  echo "\$var"
done
EOF
  )"
  assert_equal "$(cat "b_bash")" "${expected}"
}

@test 'lintball fix #!/bin/sh' {
  run lintball fix "a_sh" # 3>&-
  assert_success
  expected="$(
    cat <<EOF
#!/bin/sh

a() {
  echo

}

b() {

  echo
}
EOF
  )"
  assert_equal "$(cat "a_sh")" "${expected}"
}

@test 'lintball fix #!/usr/bin/env bash' {
  run lintball fix "a_bash" # 3>&-
  assert_success
  expected="$(
    cat <<EOF
#!/usr/bin/env bash

a() {
  echo

}

b() {

  echo
}

c=("a" "b" "c")

for var in "\${c[@]}"; do
  echo "\$var"
done
EOF
  )"
  assert_equal "$(cat "a_bash")" "${expected}"
}

@test 'lintball fix #!/usr/bin/env deno' {
  run lintball fix "b_js" # 3>&-
  assert_success
  expected="$(
    cat <<EOF
#!/usr/bin/env deno

const a = {
  a: "b",
  1: 2,
};

module.exports = {
  foo() {
    throw new Error("foo");
  },
  bar: () => ({ a: "b", 1: 2, ...a }),
};
EOF
  )"
  assert_equal "$(cat "b_js")" "${expected}"
}
@test 'lintball fix #!/usr/bin/env node' {
  run lintball fix "a_js" # 3>&-
  assert_success
  expected="$(
    cat <<EOF
#!/usr/bin/env node

const a = {
  a: "b",
  1: 2,
};

module.exports = {
  foo() {
    throw new Error("foo");
  },
  bar: () => ({ a: "b", 1: 2, ...a }),
};
EOF
  )"
  assert_equal "$(cat "a_js")" "${expected}"
}

@test 'lintball fix #!/usr/bin/env python3' {
  run lintball fix "a_py" # 3>&-
  assert_success
  expected="$(
    cat <<EOF
#!/usr/bin/env python3

"""A Python module.

This module docstring should be dedented.
"""

# pylint: disable=import-error,invalid-name

import path
import system


def a(arg):
    """This should be trimmed."""
    print(arg, "b", "c", "d")
    print(path)
    print(system)
EOF
  )"
  assert_equal "$(cat "a_py")" "${expected}"
}

@test 'lintball fix *.bash' {
  run lintball fix "a.bash" # 3>&-
  assert_success
  expected="$(
    cat <<EOF
a() {
  echo

}

b() {

  echo
}

c=("a" "b" "c")

for var in "\${c[@]}"; do
  echo "\$var"
done
EOF
  )"
  assert_equal "$(cat "a.bash")" "${expected}"
}

@test 'lintball fix *.bats' {
  run lintball fix "a.bats" # 3>&-
  assert_success
  assert_equal "$(cat "a.bats")" "$(cat "a.bats.expected")"
}

@test 'lintball fix *.css' {
  run lintball fix "a.css" # 3>&-
  assert_success
  expected="$(
    cat <<EOF
html body h1 {
  font-weight: 800;
}
EOF
  )"
  assert_equal "$(cat "a.css")" "${expected}"
}

@test 'lintball fix *.html' {
  run lintball fix "a.html" # 3>&-
  assert_success
  expected="$(
    cat <<EOF
<html>
  <head>
    <title>A</title>
  </head>

  <body>
    <h1>B</h1>
  </body>
</html>
EOF
  )"
  assert_equal "$(cat "a.html")" "${expected}"
}

@test 'lintball fix *.js' {
  run lintball fix "a.js" # 3>&-
  assert_success
  expected="$(
    cat <<EOF
const a = {
  a: "b",
  1: 2,
};

module.exports = {
  foo() {
    throw new Error("foo");
  },
  bar: () => ({ a: "b", 1: 2, ...a }),
};
EOF
  )"
  assert_equal "$(cat "a.js")" "${expected}"
}

@test 'lintball fix *.json' {
  run lintball fix "a.json" # 3>&-
  assert_success
  expected="$(
    cat <<EOF
{ "a": "b", "c": "d" }
EOF
  )"
  assert_equal "$(cat "a.json")" "${expected}"
}

@test 'lintball fix *.jsx' {
  run lintball fix "a.jsx" # 3>&-
  assert_success
  expected="$(
    cat <<EOF
/* eslint-disable import/no-unresolved */

import * as ReactDOM from "react-dom/client";

import React from "react";

ReactDOM.render(<h1>Hello, world!</h1>, document.getElementById("root"));
EOF
  )"
  assert_equal "$(cat "a.jsx")" "${expected}"
}

@test 'lintball fix *.ksh' {
  run lintball fix "a.ksh" # 3>&-
  assert_success
  expected="$(
    cat <<EOF
a() {
  echo

}

b() {

  echo
}

c=("a" "b" "c")

for var in "\${c[@]}"; do
  echo "\$var"
done
EOF
  )"
  assert_equal "$(cat "a.ksh")" "${expected}"
}

@test 'lintball fix *.md' {
  run lintball fix "a.md" # 3>&-
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

@test 'lintball fix *.mdx' {
  run lintball fix "a.mdx" # 3>&-
  assert_success
  expected="$(
    cat <<EOF
function Foo () {
return (<h1>
hello world

  </h1>);
}

<Meta title="some page" component={Foo} />

# Foo

It is a Foo!

## Example

<Foo></Foo>
EOF
  )"
  assert_equal "$(cat "a.mdx")" "${expected}"
}

@test 'lintball fix *.mksh' {
  run lintball fix "a.mksh" # 3>&-
  assert_success
  expected="$(
    cat <<EOF
a() {
  echo

}

b() {

  echo
}

c=("a" "b" "c")

for var in "\${c[@]}"; do
  echo "\$var"
done
EOF
  )"
  assert_equal "$(cat "a.mksh")" "${expected}"
}

@test 'lintball fix *.pug' {
  run lintball fix "a.pug" # 3>&-
  assert_success
  expected="$(
    cat <<EOF
html
  head
    title
      | A
  body
    h1 B
EOF
  )"
  assert_equal "$(cat "a.pug")" "${expected}"
}

@test 'lintball fix *.py' {
  run lintball fix "a.py" # 3>&-
  assert_success
  expected="$(
    cat <<EOF
"""A Python module.

This module docstring should be dedented.
"""

# pylint: disable=import-error,invalid-name

import path
import system


def a(arg):
    """This should be trimmed."""
    print(arg, "b", "c", "d")
    print(path)
    print(system)
EOF
  )"
  assert_equal "$(cat "a.py")" "${expected}"
}

@test 'lintball fix *.pyi' {
  run lintball fix "c.pyi" # 3>&-
  assert_success
  expected="$(
    cat <<EOF
"""This is a docstring."""

from typing import Optional

# pylint: disable=useless-object-inheritance,too-few-public-methods


class Foo(object):
    """This is a docstring."""
    spam: int = ...
    eggs: Optional[int] = ...
    ham: str = ...
EOF
  )"
  assert_equal "$(cat "c.pyi")" "${expected}"
}

@test 'lintball fix *.pyx' {
  run lintball fix "b.pyx" # 3>&-
  assert_success
  expected="$(
    cat <<EOF

cdef void fun(char * a) nogil:
    """test."""
    cdef:
        char * dest = a
EOF
  )"
  assert_equal "$(cat "b.pyx")" "${expected}"
}

@test 'lintball fix *.scss' {
  run lintball fix "a.scss" # 3>&-
  assert_success
  expected="$(
    cat <<EOF
html {
  body {
    h1 {
      font-weight: 800;
    }
  }
}
EOF
  )"
  assert_equal "$(cat "a.scss")" "${expected}"
}

@test 'lintball fix *.sh' {
  run lintball fix "a.sh" # 3>&-
  assert_success
  expected="$(
    cat <<EOF
a() {
  echo

}

b() {

  echo
}
EOF
  )"
  assert_equal "$(cat "a.sh")" "${expected}"
}

@test 'lintball fix *.ts' {
  run lintball fix "a.ts" # 3>&-
  assert_success
  expected="$(
    cat <<EOF
interface Interface {
  foo: string;
  bar: string;
}
const message = "Hello World";
console.log(message);
EOF
  )"
  assert_equal "$(cat "a.ts")" "${expected}"
}

@test 'lintball fix *.tsx' {
  run lintball fix "a.tsx" # 3>&-
  assert_success
  expected="$(
    cat <<EOF
/* eslint-disable import/no-unresolved */

import React from "react";

export interface HelloWorldProps {
  name: string;
}

/* eslint-disable react/prefer-stateless-function */
export default class HelloWorld extends React.Component<HelloWorldProps> {
  render() {
    const { name } = this.props;
    return <div>{name}</div>;
  }
}
EOF
  )"
  assert_equal "$(cat "a.tsx")" "${expected}"
}

@test 'lintball fix *.xml' {
  run lintball fix "a.xml" # 3>&-
  assert_success
  expected="$(
    cat <<EOF
<?xml version="1.0" encoding="UTF-8" ?>
<items>
    <a>A</a>
    <b>B</b>
    <c />
</items>
EOF
  )"
  assert_equal "$(cat "a.xml")" "${expected}"
}

@test 'lintball fix *.yml' {
  run lintball fix "a.yml" # 3>&-
  assert_success
  expected="$(
    cat <<EOF
key: value
hello: world
EOF
  )"
  assert_equal "$(cat "a.yml")" "${expected}"
}

@test 'lintball fix handles implicit path' {
  mkdir foo
  cd foo
  run lintball fix # 3>&-
  assert_success
  assert_line "No handled files found in current directory."
}

@test 'lintball fix handles . path' {
  mkdir foo
  cd foo
  run lintball fix . # 3>&-
  assert_success
  assert_line "No handled files found in directory '.'."
}

@test 'lintball fix handles paths with spaces' {
  mkdir -p "aaa aaa/bbb bbb"
  cp "a.yml" "aaa aaa/bbb bbb/a b.yml"
  run lintball fix "aaa aaa/bbb bbb/a b.yml" # 3>&-
  assert_success
  expected="$(
    cat <<EOF
key: value
hello: world
EOF
  )"
  assert_equal "$(cat "aaa aaa/bbb bbb/a b.yml")" "${expected}"
}

@test 'lintball fix package.json' {
  run lintball fix "package.json" # 3>&-
  assert_success
  expected="$(
    cat <<EOF
{
  "main": "a.js",
  "name": "fixture",
  "version": "1.0.0",
  "scripts": {
    "test": "echo \"Error: no test specified\" && exit 1"
  },
  "author": "",
  "license": "ISC",
  "description": ""
}
EOF
  )"
  assert_equal "$(cat "package.json")" "${expected}"
}

@test 'lintball fix ignored file fails' {
  run lintball fix "a.txt" # 3>&-
  assert_success
  assert_line "File not handled: 'a.txt'."
}

@test 'lintball fix ignored directory fails' {
  mkdir a_dir
  cp a.yml a_dir/
  run lintball fix "a_dir" # 3>&-
  assert_success
  assert_line "No handled files found in directory 'a_dir'."
}

@test 'lintball fix ignored file in ignored directory fails' {
  mkdir a_dir
  cp a.txt a_dir/
  run lintball fix "a_dir" # 3>&-
  assert_success
  assert_line "No handled files found in directory 'a_dir'."
}

@test 'lintball fix handled file in ignored directory fails' {
  mkdir a_dir
  cp a.yml a_dir/
  run lintball fix "a_dir/a.yml" # 3>&-
  assert_success
  assert_line "File not handled with current configuration: 'a_dir/a.yml'."
}

@test 'lintball fix missing' {
  run lintball fix "missing.txt" # 3>&-
  assert_failure
  assert_line "File not found: 'missing.txt'."

  run lintball fix "missing1.txt" "missing2.txt" # 3>&-
  assert_failure
  assert_line "File not found: 'missing1.txt'."
  assert_line "File not found: 'missing2.txt'."
}
