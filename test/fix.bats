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
  assert [ "$(echo "${output}" | grep -cF " ↳ yamllint...........................wrote" -c)" -eq 1 ]
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
  assert [ "$(echo "${output}" | grep -cF " ↳ yamllint...........................wrote")" -eq 1 ]
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

@test 'lintball fix #!/usr/bin/env ruby' {
  run lintball fix "a_rb" # 3>&-
  assert_success
  expected="$(
    cat <<EOF
#!/usr/bin/env ruby
# frozen_string_literal: true
d = [123, 456, 789]

echo d
EOF
  )"
  assert_equal "$(cat "a_rb")" "${expected}"
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

@test 'lintball fix *.c' {
  run lintball fix "a.c" # 3>&-
  assert_success
  expected="$(
    cat <<EOF
#include <stdio.h>

int main() {
    printf("Hello World!");
    return 0;
}
EOF
  )"
  assert_equal "$(cat "a.c")" "${expected}"
}

@test 'lintball fix *.cpp' {
  run lintball fix "a.cpp" # 3>&-
  assert_success
  expected="$(
    cat <<EOF
#include <iostream>
using namespace std;

namespace HelloWorld {
class Hello {
    void func() {
        cout << "Inside func" << endl;
    }
}
}
int main() {
    std::cout << "Hello World!";
    return 0;
}
EOF
  )"
  assert_equal "$(cat "a.cpp")" "${expected}"
}

@test 'lintball fix *.cs' {
  run lintball fix "a.cs" # 3>&-
  assert_success
  expected="$(
    cat <<EOF
namespace HelloWorld {
class Hello {
    static void Main(string[] args) {
        System.Console.WriteLine("Hello World!");
    }
}
}
EOF
  )"
  assert_equal "$(cat "a.cs")" "${expected}"
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

@test 'lintball fix *.d' {
  run lintball fix "a.d" # 3>&-
  assert_success
  expected="$(
    cat <<EOF

import std.stdio;

void main() {
    writeln("Hello, World!");
}
EOF
  )"
  assert_equal "$(cat "a.d")" "${expected}"
}

@test 'lintball fix *.dash' {
  run lintball fix "a.dash" # 3>&-
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
  assert_equal "$(cat "a.dash")" "${expected}"
}

@test 'lintball fix *.h' {
  run lintball fix "a.h" # 3>&-
  assert_success
  expected="$(
    cat <<EOF
#include <stdio.h>

int main();
EOF
  )"
  assert_equal "$(cat "a.h")" "${expected}"
}

@test 'lintball fix *.hpp' {
  run lintball fix "a.hpp" # 3>&-
  assert_success
  expected="$(
    cat <<EOF
#include <iostream>

int main();
EOF
  )"
  assert_equal "$(cat "a.hpp")" "${expected}"
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

@test 'lintball fix *.java' {
  run lintball fix "a.java" # 3>&-
  assert_success
  expected="$(
    cat <<EOF
class HelloWorld {

  public static void main(String[] args) {
    System.out.println("Hello, World!");
  }
}
EOF
  )"
  assert_equal "$(cat "a.java")" "${expected}"
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

@test 'lintball fix *.lua' {
  run lintball fix "a.lua" # 3>&-
  assert_success
  expected="$(
    cat <<EOF
type A = { b: number, c: number }

local a: A = { b = 1, c = 2 }

print(a.b, a.c)
EOF
  )"
  assert_equal "$(cat "a.lua")" "${expected}"
}

@test 'lintball fix *.m' {
  run lintball fix "a.m" # 3>&-
  assert_success
  expected="$(
    cat <<EOF
#import <Foundation/Foundation.h>

int main(int argc, const char *argv[]) {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc]init];

    NSLog(@"Hello, World!");
    [pool drain];
    return 0;
}
EOF
  )"
  assert_equal "$(cat "a.m")" "${expected}"
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

@test 'lintball fix *.nim' {
  run lintball fix "a.nim" # 3>&-
  assert_success
  expected="$(
    cat <<EOF
type
  A* = int
  B* = int

proc my_foo(a: string, b: string, c: int, ): string =
  raise newException (Exception,
    "foo")
  foo (a, b, c)
  d [a] = 3
  discard "string to discard"

  break
  return "string to return"
EOF
  )"
  assert_equal "$(cat "a.nim")" "${expected}"
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

@test 'lintball fix *.rb' {
  run lintball fix "a.rb" # 3>&-
  assert_success
  expected="$(
    cat <<EOF
# frozen_string_literal: true
d = [123, 456, 789]

echo d
EOF
  )"
  assert_equal "$(cat "a.rb")" "${expected}"
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

@test 'lintball fix Cargo.toml' {
  run lintball fix "Cargo.toml" # 3>&-
  expected="$(
    cat <<EOF

#![allow(clippy::stable_sort_primitive)]


fn unnecessary_sort_by() {
    fn id(x: isize) -> isize {
        x
    }
    let mut vec: Vec<isize> = vec![3, 6, 1, 2, 5];
    // Forward examples
    vec.sort();
    vec.sort_unstable();
    vec.sort_by_key(|a| (a + 5).abs());
    vec.sort_unstable_by_key(|a| id(-a));
}

fn main() {
    unnecessary_sort_by();
}
EOF
  )"
  assert_success
  assert_equal "$(cat "src/main.rs")" "${expected}"
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
