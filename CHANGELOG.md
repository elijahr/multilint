# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.0.0] - 2024-11-04

### Added

- consistent tool installation and versioning via asdf
- Docker containers
- GitHub action

### Fixed

- pre-commit path issue
- tool installation failing silently

### Removed

- Language support: nim, rust, c/c++/d, ruby, java, c#, lua

## [1.6.0] - 2022-11-09

### Added

- nimfmt support
- upgrade uncrustify configs

## [1.5.0] - 2022-03-28

### Changed

- Upgrade black to 22.3.0
- Upgrade pylint to 2.13.2

## [1.4.3] - 2022-01-27

### Changed

- Add workaround for buggy virtualenv scripts.

## [1.4.1] - 2021-12-07

### Changed

- Upgrade Python requirements: `autoflake`, `autopep8`, `black`, `docformatter`, `isort`, `pylint`, & `yamllint`.
- Remove README note about Apple Silicon / shellcheck (ghc works now).

## [1.3.0] - 2021-06-11

### Added

- Add pylint support.

## [1.2.3] - 2021-02-24

### Added

- Check for bash >= 4.

## [1.2.2] - 2021-02-11

### Changed

- Fix sporadic hanging issue with parallel runs.

## [1.2.1] - 2021-02-03

### Added

- `--jobs` argument, for parallel runs.
- Support for Python type stub files (`*.pyi`).
- Support for Python in Windows (thanks @qiaozha!) #2

### Changed

- Fix yamllint path issue.
- Fix issue where black would not run due to "mach-o, wrong architecture" in dependencies.

## [1.1.11] - 2021-01-27

### Changed

- autoflake: don't remove "unused" imports in **init**.py

## [1.1.10] - 2021-01-27

### Added

- Added support for MDX.

### Changed

- Fixed GitHub Actions example in README using `--since`.

## [1.1.9] - 2021-01-27

### Added

- Helpful error message if pre-commit hook can't find `lintball` command.

### Changed

- Disable pre-commit hook during rebase.

## [1.1.8] - 2021-01-27

### Changed

- Configure `autopep8` and `isort` to play nicely with `black`.

## [1.1.7] - 2021-01-27

### Changed

- Proper handling of deleted files in pre-commit git hook.
- Proper handling of deleted files in `fix`/`check` with `--since`.

## [1.1.6] - 2021-01-26

### Changed

- Fix `check` and `fix` issue when no path argument is provided (regression from
  1.1.4).

## [1.1.5] - 2021-01-26

### Changed

- Fix `--version`.

## [1.1.4] - 2021-01-26

### Added

- `--since` option for `fix` and `check` commands, for checking only files
  changed after a specific git commit.
- Changelog
