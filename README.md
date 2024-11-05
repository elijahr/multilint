![Test](https://github.com/elijahr/lintball/workflows/Test/badge.svg?branch=devel)
![Platforms](https://img.shields.io/badge/platform-linux%20%7C%20macos%20-lightgrey)

```
█   █ █▄ █ ▀█▀ ██▄ ▄▀▄ █   █
█▄▄ █ █ ▀█  █  █▄█ █▀█ █▄▄ █▄▄
keep your entire project tidy with one command.
```

lintball is a wrapper script around linters (static code analysis tools) and code formatters (such as prettier, black, etc).

## Why use lintball?

Most software projects consist of more than one programming language. There's source code, documentation, configuration files, build scripts, and so on. Each language may have tools to find and fix issues - but configuring CI, git hooks, etc for each of these tools can be tedious - especially if you work on a lot of projects. The goal of lintball is to streamline the installation and running of these tools so that you have more time for the more fun and important things.

## Supported languages

| Language     | Detection                                |                                        Tools used                                        |
| :----------- | ---------------------------------------- | :--------------------------------------------------------------------------------------: |
| bash         | `*.bash`, `#!/usr/bin/env bash`          |                               [shellcheck][1], [shfmt][1]                                |
| bats         | `*.bats`, `#!/usr/bin/env bats`          |                               [shellcheck][1], [shfmt][2]                                |
| CSS          | `*.css`                                  |                                      [prettier][4]                                       |
| Cython       | `*.pyx`, `*.pxd`, `*.pxi`                |                     [autoflake][5], [autopep8][6], [docformatter][7]                     |
| GraphQL      | `*.graphql`                              |                                      [prettier][4]                                       |
| HTML         | `*.html`                                 |                                      [prettier][4]                                       |
| JavaScript   | `*.js`, `*.cjs`, `#!/usr/bin/env node`   |                                [eslint][9],[prettier][4]                                 |
| JSON         | `*.json`                                 |                                      [prettier][4]                                       |
| JSX          | `*.jsx`                                  |                                [eslint][9],[prettier][4]                                 |
| ksh          | `*.ksh`, `#!/usr/bin/env ksh`            |                               [shellcheck][1], [shfmt][2]                                |
| Markdown     | `*.md`                                   |                                      [prettier][4]                                       |
| MDX          | `*.mdx`                                  |                                      [prettier][4]                                       |
| mksh         | `*.mksh`, `#!/usr/bin/env mksh`          |                               [shellcheck][1], [shfmt][2]                                |
| package.json | `package.json`                           |                               [prettier-package-json][12]                                |
| pug          | `*.pug`                                  |                                [prettier/plugin-pug][13]                                 |
| Python       | `*.py`, `*.pyi`, `#!/usr/bin/env python` | [autoflake][5], [autopep8][6], [black][14], [docformatter][7], [isort][15], [pylint][22] |
| SASS         | `*.scss`                                 |                                      [prettier][4]                                       |
| sh           | `*.sh`, `#!/bin/sh`                      |                               [shellcheck][1], [shfmt][2]                                |
| TSX          | `*.tsx`                                  |                                [eslint][9],[prettier][4]                                 |
| TypeScript   | `*.ts`                                   |                                [eslint][9],[prettier][4]                                 |
| XML          | `*.xml`                                  |                                [prettier/plugin-xml][19]                                 |
| YAML         | `*.yml`, `*.yaml`                        |                              [prettier][4], [yamllint][20]                               |

## Installation

```sh
npm install -g lintball

cd my-project

# Auto-detect formatters for my-project, install them.
lintball install-tools

# Install git pre-commit hook to detect and auto-fix issues in my-project.
lintball install-githooks
```

## Usage

```
Usage:
  lintball [-h | -v]
  lintball [-c <path>] check [--since <commit>] [--jobs <n>] [paths …]
  lintball [-c <path>] fix [--since <commit>] [--jobs <n>] [paths …]
  lintball [-c <path>] install-githooks [-y | -n] [-p <path>]
  lintball [-c <path>] install-lintballrc [-y | -n] [-p <path>]
  lintball [-c <path>] install-tools [-y | -n] [-a] [-p <path>] [ext …]
  lintball [-c <path>] pre-commit

Options:
  -h, --help                Show this help message & exit.
  -v, --version             Print version & exit.
  -c, --config <path>       Use the config file at <path>.

Subcommands:
  check [paths …]           Recursively check for issues.
                              Exit 1 if any issues.
    -s, --since <commit>    Check only files changed since <commit>. This
                            includes both committed and uncommitted changes.
                            <commit> may be a commit hash or a committish, such
                            as HEAD^1 or master.
    -j, --jobs <n>          The number of parallel jobs to run.
                              Default: the number of available CPUs.
  fix [paths …]             Recursively fix issues.
                              Exit 1 if unfixable issues.
    -s, --since <commit>    Fix only files changed since <commit>. This
                            includes both committed and uncommitted changes.
                            <commit> may be a commit hash or a committish, such
                            as HEAD^1 or master.
    -j, --jobs <n>          The number of parallel jobs to run.
                              Default: the number of available CPUs.
  install-githooks          Install lintball githooks in a git repository.
    -p, --path <path>       Git repo path.
                              Default: working directory.
    -y, --yes               Skip prompt & replace repo's githooks.
    -n, --no                Skip prompt & exit 1 if repo already has githooks.
  install-lintballrc        Create a default .lintballrc.json config file.
    -p, --path <path>       Where to install the config file.
                              Default: working directory
    -y, --yes               Skip prompt & replace existing .lintballrc.json.
    -n, --no                Skip prompt & exit 1 if .lintballrc.json exists.
  install-tools [ext …]     Install tools for fixing files having extensions
                            [ext]. If no [ext] are provided, lintball will
                            autodetect which tools to install based on files in
                            <path>.
    -p, --path <path>       The path to search for file types.
                              Default: working directory
    -y, --yes               Skip prompt & install missing dependencies.
    -a, --all               Install *all* tools.
  pre-commit                Recursively fix issues on files that are fully
                            staged for commit. Recursively check for issues on
                            files that are partially staged for commit.
                              Exit 1 if unfixable issues on fully staged files.
                              Exit 1 if any issues on partially staged files.

Examples:
  $ lintball check                       # Check working directory for issues.
  $ lintball check --since HEAD^1        # Check working directory for issues
                                         # in all files changes since the commit
                                         # before last.
  $ lintball check foo                   # Check the foo directory for issues.
  $ lintball check foo.py                # Check the foo.py file for issues.
  $ lintball fix                         # Fix issues in the working directory.
  $ lintball -c foo/.lintballrc.json fix # Fix issues in the working directory
                                         # using the specified config.
  $ lintball fix foo                     # Fix issues in the foo directory.
  $ lintball fix foo.py                  # Fix issues in the foo.py file.
  $ lintball install-githooks -p foo     # Install githooks in directory foo.
  $ lintball install-githooks --yes      # Install a githooks config, replacing
                                         # any existing githooks config.
  $ lintball install-lintballrc          # Install a default .lintballrc.json
                                         # in the working directory.
  $ lintball install-lintballrc -p foo   # Install default .lintballrc.json in
                                         # directory foo.
  $ lintball install-tools               # Autodetect tools for working
                                         # directory and install them.
  $ lintball install-tools -p foo        # Autodetect tools for directory foo
                                         # and install them.
  $ lintball install-tools --all         # Install all tools.
  $ lintball install-tools py js yaml    # Install tools for checking Python,
                                         # JavaScript, & YAML.
```

## Updating to latest lintball

```sh
npm install --upgrade -g lintball

cd my-project

# Auto-detect formatters for my-project, install them.
# Must be re-run after updating.
lintball install-tools
```

## Continuous Integration

An example GitHub Actions workflow for linting your project:

```yml
# yamllint disable rule:line-length

name: Lint
on:
  pull_request:
    branches: ["*"]
  push:
    branches: ["*"]
    tags: ["*"]

jobs:
  lint:
    name: lint

    runs-on: ubuntu-latest

    steps:
      - name: Checkout code
        uses: actions/checkout@v3

      - uses: actions/setup-node@v2
        with:
          node-version: "15"

      - name: Install lintball
        run: |
          npm install -g lintball
          lintball install-tools

      - name: Check for linter issues
        run: lintball check
```

If you have a large project with many files, you may want to limit the number of files checked using the `--since` option. You can also tell lintball which tools to install for a faster run. Assuming your repo's default branch is named `master`:

```yaml
- name: Install lintball
  run: |
    npm install -g lintball
    lintball install-tools py js yml # Put extensions here for languages in your project

- name: Check for linter issues
  shell: bash
  run: |
    set -euxo pipefail

    default_branch=master
    if [ "$GITHUB_REF" = "refs/heads/$default_branch" ]; then
      # A push to the default branch.
      # Check files which were changed in the most recent commit.
      commitish="HEAD^1"
    elif [ -n "$GITHUB_BASE_REF" ]; then
      # A pull request.
      # Check files which have changed between the merge base and the
      # current commit.
      IFS= read -r commitish < <(git merge-base -a refs/remotes/origin/$GITHUB_BASE_REF $GITHUB_SHA)
    else
      # A push to a non-default, non-PR branch.
      # Check files which have changed between default branch and the current
      # commit.
      IFS= read -r commitish < <(git merge-base -a refs/remotes/origin/${default_branch} $GITHUB_SHA)
    fi

    if ! lintball check --since "$commitish"; then
      status=$?
      echo
      echo "The above issues were found by lintball."
      echo "To detect and auto-fix issues before pushing, install lintball's git hooks."
      echo "See https://github.com/elijahr/lintball"
      echo
      exit $status
    fi
```

## Configuration

### Ignore patterns

By default, lintball will not process files matching the following globs:

```sh
*/.build/*
*/.bundle/*
*/.cache/*
*/.git/*
*/.hg/*
*/.next/*
*/.serverless_nextjs/*
*/.tmp/*
*/.tox/*
*/__pycache__/*
*/build/*
*/dist/*
*/Gemfile.lock
*/node_modules/*
*/package-lock.json
*/Pipfile.lock
*/target/*
*/tmp/*
*/vendor/*
```

To add or remove items from this list, run `lintball install-lintballrc` and edit the `ignores` section in the created `.lintballrc.json` file. Ignore patterns are [Full Name Patterns](https://www.gnu.org/software/findutils/manual/html_node/find_html/Full-Name-Patterns.html) passed to the `find` command's `-path` argument. See also: [fnmatch](https://docs.python.org/3/library/fnmatch.html).

### Disabling specific tools

If you need to disable a tool, create a `.lintballrc.json` file in your project and add a `use` section with only the tools enabled that you wish to use. Note that to disable a tool, explicitly set its value to `false`, otherwise the default value of `true` will take precedence. The default `use` section is defined in [configs/lintballrc-defaults.json][21].

### Tool configuration

Many of the tools used by lintball can be configured to suit your needs. See:

- autopep8: https://pypi.org/project/autopep8/#configuration
- eslint: https://eslint.org/docs/user-guide/configuring
- prettier: https://prettier.io/docs/en/configuration.html
- shellcheck: https://www.mankier.com/1/shellcheck#RC_Files

If you need to pass custom arguments to a tool (such as specifying a config file), create a `.lintballrc.json` file in your project with custom `write_args` and `check_args`. The default `write_args` and `check_args` are defined in [configs/lintballrc-defaults.json][21].

### Platform support

```shell
curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh | arch -x86_64 /bin/bash
arch -x86_64 /usr/local/Homebrew/bin/brew install shellcheck
shellcheck --version
```

## Acknowledgements

lintball is a wrapper around existing tools. Many thanks to the authors of the tools used by lintball!

## Contributing

Pull requests are welcome! lintball has a suite of unit tests, located in the `test` directory. The tests can be run with `/scripts/run-tests-external.sh`. Please ensure that your features or fixes come with unit tests.

[1]: https://www.shellcheck.net/
[2]: https://github.com/mvdan/sh
[4]: https://prettier.io/
[5]: https://pypi.org/project/autoflake/
[6]: https://pypi.org/project/autopep8/
[7]: https://pypi.org/project/docformatter/
[9]: https://github.com/eslint/eslint
[12]: https://github.com/cameronhunter/prettier-package-json
[13]: https://github.com/prettier/plugin-pug
[14]: https://github.com/psf/black
[15]: https://pypi.org/project/isort/
[19]: https://github.com/prettier/plugin-xml
[20]: https://yamllint.readthedocs.io/en/stable/
[21]: https://github.com/elijahr/lintball/tree/devel/configs/lintballrc-defaults.json
[22]: http://pylint.pycqa.org/
