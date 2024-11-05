#!/usr/bin/env bash

# shellcheck disable=SC2230

cli_entrypoint() {
  local status bash_major_version
  # shellcheck disable=SC2001
  IFS= read -r bash_major_version < <(parse_major_version "text=${BASH_VERSION}")

  if [[ ${bash_major_version} -lt "4" ]]; then
    echo "Unsupported bash version ${bash_major_version}: must be >=4"
    if command -v brew; then
      echo "Try: brew install bash"
    fi
    exit 1
  fi

  local config mode commit num_jobs paths fn path answer all status
  config=""

  # Parse base options
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -h | --help)
        usage >&2
        support_table >&2
        documentation_link >&2
        return 0
        ;;
      -v | --version)
        jq --raw-output ".version" <"${LINTBALL_DIR}/package.json"
        return 0
        ;;
      -c | --config)
        shift
        if [[ -z ${1:-} ]]; then
          echo "No config passed for --config" >&2
          return 1
        fi
        config="$1"
        shift
        ;;
      -*)
        echo >&2
        echo "Unknown option $1" >&2
        usage >&2
        documentation_link >&2
        return 1
        ;;
      *)
        break
        ;;
    esac
  done
  if [[ -z ${config} ]]; then
    IFS= read -r config < <(config_find "${PWD}") || true
  fi
  answer=""
  all="all=no"

  # Load default configs
  config_load "path=${LINTBALL_DIR}/configs/lintballrc-defaults.json"
  config_load "path=${LINTBALL_DIR}/configs/lintballrc-ignores.json"

  if [[ -n ${config} ]]; then
    echo
    echo "lintball using config: $(prettify_path "${config}")"
    echo
    config_load "path=${config}"
  fi

  declare -a paths=()

  num_jobs="${LINTBALL_NUM_JOBS}"

  # Parse subcommand
  case "${1:-}" in
    check | fix)
      case "$1" in
        check) mode="check" ;;
        fix) mode="write" ;;
      esac
      shift
      while true; do
        case "${1:-}" in
          -s | --since)
            shift
            commit="$1"
            shift
            if ! git rev-parse --is-inside-work-tree 1>/dev/null 2>/dev/null; then
              echo "Not in a git repository, cannot use --since" >&2
              git rev-parse --is-inside-work-tree || true
              return 1
            fi
            if ! git rev-parse "${commit}" 1>/dev/null 2>/dev/null; then
              if [[ "$(git rev-parse --is-shallow-repository)" == "true" ]]; then
                echo "Shallow repository, cannot use --since with a commit hash" >&2
                echo "If this is being run from the lintball GitHub Action, set fetch-depth: 0" >&2
                echo "in the checkout step." >&2
                return 1
              else
                echo "Invalid commit: ${commit}" >&2
                git rev-parse "${commit}" || true
                return 1
              fi
            fi
            readarray -t -O"${#paths[@]}" paths < <(get_paths_changed_since_commit "${commit}")
            ;;
          -j | --jobs)
            shift
            num_jobs="$1"
            shift
            ;;
          -*)
            if [[ -f $1 ]] || [[ -d $1 ]]; then
              continue
            fi
            echo >&2
            echo "Unknown option $1" >&2
            usage >&2
            documentation_link >&2
            echo >&2
            return 1
            ;;
          *)
            if [[ -n ${1:-} ]]; then
              # shellcheck disable=SC2206
              paths+=("$@")
            fi
            break
            ;;
        esac
      done
      status=0
      subcommand_process_files "mode=${mode}" "num_jobs=${num_jobs}" "${paths[@]}"
      return $?
      ;;
    pre-commit)
      if git rebase --show-current-patch 2>/dev/null; then
        echo "Rebase in progress, not running lintball pre-commit hook."
        echo
        return 0
      fi
      shift
      readarray -t -O"${#paths[@]}" paths < <(get_fully_staged_paths)
      if [[ ${#paths[@]} -eq 0 ]]; then
        echo "No fully staged files, nothing to do."
        return 0
      fi
      subcommand_process_files "mode=write" "num_jobs=${num_jobs}" "${paths[@]}"
      status=$?
      for path in "${paths[@]}"; do
        git add "${path}"
      done
      return "${status}"
      ;;
    install-githooks | install-lintballrc | install-tools | clean-tools)
      fn="subcommand_${1//-/_}"
      shift
      while [[ $# -gt 0 ]]; do
        case "$1" in
          -y | --yes)
            answer="yes"
            shift
            ;;
          -n | --no)
            answer="no"
            shift
            ;;
          -a | --all)
            all="yes"
            shift
            ;;
          -p | --path)
            shift
            path="$1"
            shift
            ;;
          -*)
            echo >&2
            echo "Unknown option $1" >&2
            usage >&2
            documentation_link >&2
            echo >&2
            return 1
            ;;
          *)
            break
            ;;
        esac
      done
      path="${path:-${PWD}}"
      if [[ ${fn} == "subcommand_install_tools" ]]; then
        # Pass extensions to install_tools
        "${fn}" "path=${path}" "all=${all}" "$@"
        return $?
      elif [[ ${fn} == "subcommand_clean_tools" ]]; then
        "${fn}" "path=${path}" "answer=${answer}"
        return $?
      else
        if [[ $# -gt 0 ]]; then
          echo "${fn}: unexpected argument '$1'" >&2
          echo >&2
          return 1
        fi
        "${fn}" "path=${path}" "answer=${answer}"
        return $?
      fi
      ;;
    *)
      if [[ -z ${1:-} ]]; then
        echo "missing subcommand" >&2
      else
        echo "unknown subcommand '$1'" >&2
      fi
      usage >&2
      documentation_link >&2
      return 1
      ;;
  esac
}

on_exit() {
  local status=$? tmp pid
  tmp="${1#tmp=}"

  # Kill consumers
  set +f
  for pidfile in "${tmp}/"*.pid; do
    IFS= read -r pid < <(cat "${pidfile}")
    kill -TERM "$pid" 1>/dev/null 2>/dev/null || true
    if ps -p "$pid" >/dev/null; then
      kill -KILL "$(cat "${pidfile}")" 1>/dev/null 2>/dev/null || true
    fi
  done
  set -f

  # Cleanup
  rm -rf "${tmp}"
  exit "${status}"
}

subcommand_process_files() {
  local mode num_jobs consumer tmp status ready pid pids
  mode="${1#mode=}"
  num_jobs="${2#num_jobs=}"
  shift
  shift

  if [[ ${num_jobs} == "auto" ]]; then
    if command -v nproc >/dev/null; then
      # coreutils
      IFS= read -r num_jobs < <(nproc)
    elif command -v sysctl; then
      # macOS
      IFS= read -r num_jobs < <(sysctl -n hw.ncpu)
    else
      # who knows
      num_jobs="4"
    fi
  fi
  num_jobs=1

  IFS= read -r tmp < <(mktemp -d)

  trap 'trap - HUP; kill -HUP $$' HUP
  trap 'trap - INT; kill -INT $$' INT
  trap 'trap - TERM; kill -TERM $$' TERM
  # shellcheck disable=SC2064
  trap "on_exit 'tmp=${tmp}'" EXIT

  # Initialize consumer subprocesses
  declare -a pids=()
  for ((consumer = 1; consumer <= num_jobs; consumer++)); do
    mkfifo "${tmp}/${consumer}.queue"
    consume "tmp=${tmp}" "consumer=${consumer}" "mode=${mode}" &
    pid="$!"
    echo "$pid" >"${tmp}/${consumer}.pid"
    pids+=("$pid")
  done

  while true; do
    ready="yes"
    for ((consumer = 1; consumer <= num_jobs; consumer++)); do
      if [[ ! -f "${tmp}/${consumer}.ready" ]]; then
        ready="no"
        break
      fi
    done
    if [[ ${ready} == "yes" ]]; then
      break
    fi
  done

  # Send paths to consumers
  produce "tmp=${tmp}" "num_jobs=${num_jobs}" "$@"

  status=0
  for pid in "${pids[@]}"; do
    wait "$pid" || status=$?
  done

  return "${status}"
}

process_file() {
  local path mode extension tools tool lang status
  path="${1#path=}"
  shift
  mode="${1#mode=}"
  shift
  IFS= read -r path < <(normalize_path "path=${path}")

  IFS= read -r extension < <(normalize_extension "path=${path}")

  prettify_path "${path}"
  status=0
  for tool in "$@"; do
    case "${tool}" in
      prettier) run_tool_prettier "mode=${mode}" "path=${path}" || status=$? ;;
      eslint) run_tool_eslint "mode=${mode}" "path=${path}" || status=$? ;;
      shellcheck)
        IFS= read -r lang < <(get_lang_shellcheck "extension=${extension}")
        run_tool_shellcheck "mode=${mode}" "path=${path}" "lang=${lang}" || status=$?
        ;;
      shfmt)
        IFS= read -r lang < <(get_lang_shfmt "extension=${extension}")
        run_tool_shfmt "mode=${mode}" "path=${path}" "lang=${lang}" || status=$?
        ;;
      *) run_tool "tool=${tool}" "mode=${mode}" "path=${path}" || status=$? ;;
    esac
    if [[ ${status} -ne 0 ]]; then
      echo
    fi
  done
  return $status
}

subcommand_install_githooks() {
  local path answer git_dir hooks_path hook dest status
  path="${1#path=}"
  answer="${2#answer=}"

  IFS= read -r git_dir < <(find_git_dir "dir=${path}") || true
  if [[ -z ${git_dir} ]]; then
    echo >&2
    echo "Could not find a .git directory at or above ${path}" >&2
    echo >&2
    return 1
  fi

  IFS= read -r hooks_path < <(git --git-dir="${git_dir}" config --local core.hooksPath) || true
  if [[ -z ${hooks_path} ]]; then
    hooks_path="${path}/.githooks"
  fi

  if [[ ! -d ${hooks_path} ]]; then
    hooks_basename=$(basename "${hooks_path}")
    if [[ -d "${path}/${hooks_basename}" ]]; then
      hooks_path="${path}/${hooks_basename}"
    else
      echo "Error: Hooks path ${hooks_path} does not exist and ${path}/${hooks_basename} is also not a valid directory." >&2
      echo "If this is being run in docker, make sure your project is mounted as a volume correctly." >&2
      return 1
    fi
  fi

  if command -v realpath >/dev/null 2>&1; then
    if [[ ${hooks_path} == /* ]]; then
      hooks_path=$(realpath --relative-to="${path}" "${hooks_path}")
    fi
  fi

  set +f
  for hook in "${LINTBALL_DIR}/githooks/"*; do
    dest="${hooks_path}/$(basename "${hook}")"
    confirm_copy "src=${hook}" "dest=${dest}" "answer=${answer}"
  done
  set -f

  git --git-dir="${git_dir}" config --local core.hooksPath "${hooks_path}"
  echo
  echo "Set git hooks path → ${hooks_path}"
  echo
  return 0
}

subcommand_install_lintballrc() {
  local path answer
  path="${1#path=}"
  answer="${2#answer=}"
  confirm_copy \
    "src=${LINTBALL_DIR}/configs/lintballrc-ignores.json" \
    "dest=${path}/.lintballrc.json" \
    "answer=${answer}"
}

subcommand_install_tools() {
  local path paths all extension tools tool file installed is_installed installer
  path="${1#path=}"
  all="${2#all=}"
  shift
  shift
  declare -a tools=()
  declare -a installed=()
  if [[ ${all} == "yes" ]]; then
    # install everything
    tools+=("${LINTBALL_ALL_TOOLS[@]}")
  elif [[ $# -gt 0 ]]; then
    # extensions provided by user on command line
    for extension in "${@}"; do
      readarray -t -O"${#tools[@]}" tools < <(get_tools_for_file "path=_.${extension}")
    done
  else
    # examine path to find tools to install
    populate_find_args "${path}"
    while read -r file; do
      readarray -t -O"${#tools[@]}" tools < <(get_tools_for_file "path=${file}")
    done < <(find "${LINTBALL_FIND_ARGS[@]}")
  fi

  for tool in "${tools[@]}"; do
    IFS= read -r installer < <(get_installer_for_tool "tool=${tool}")
    if [[ -z ${installer} ]]; then
      continue
    fi
    is_installed=no
    for i in "${!installed[@]}"; do
      if [[ ${installed[${i}]} == "${installer}" ]]; then
        is_installed=yes
        break
      fi
    done
    if [[ ${is_installed} == "no" ]]; then
      "${installer}"
      installed+=("${installer}")
    fi
  done
}

subcommand_clean_tools() {
  local path answer paths existing_paths
  path="${1#path=}"
  answer="${2#answer=}"

  declare -a paths=(
    "${LINTBALL_DIR}/tools/.bundle"
    "${LINTBALL_DIR}/tools/asdf"
    "${LINTBALL_DIR}/tools/bin"
    "${LINTBALL_DIR}/tools/node_modules"
    "${LINTBALL_DIR}/tools/uncrustify"*
  )
  declare -a existing_paths=()

  for path in "${paths[@]}"; do
    if [[ -e ${path} ]]; then
      existing_paths+=("${path}")
    fi
  done

  if [[ ${#existing_paths[@]} -eq 0 ]]; then
    echo "No paths to delete" >&2
    return 0
  fi

  if [[ -n ${answer} ]] && [[ ${answer} != "yes" ]]; then
    echo "--no passed, but would delete:" >&2
    for path in "${existing_paths[@]}"; do
      echo "- ${path}" >&2
    done
    return 0
  fi

  echo "Will delete the following paths:" >&2
  echo >&2
  for path in "${existing_paths[@]}"; do
    echo "- ${path}" >&2
  done
  echo >&2

  if [[ ${answer} != "yes" ]]; then
    while true; do
      printf '%s' "Proceed? [y/n] " >&2
      read -r answer
      case "${answer}" in
        y | Y | yes) break ;;
        n | N | no) return 1 ;;
        *) echo "${answer@Q} is not a valid answer." >&2 ;;
      esac
    done
  fi
  for path in "${existing_paths[@]}"; do
    rm -rf "${path}"
    echo "Deleted ${path}" >&2
  done
}

locked_echo() {
  local consumer lockfile
  consumer="${1#consumer=}"
  lockfile="${2#lockfile=}"
  # spin lock to show output
  (
    set -o noclobber
    # shellcheck disable=SC2188
    while ! { >"${lockfile}"; } 2>/dev/null; do
      sleep 0.001
    done
    cat "${tmp}/${consumer}.stdout"
    cat "${tmp}/${consumer}.stderr" >&2
    rm "${lockfile}"
    set +o noclobber
  )
}

consume() {
  local tmp consumer mode path tools status

  tmp="${1#tmp=}"
  consumer="${2#consumer=}"
  mode="${3#mode=}"

  touch "${tmp}/${consumer}.ready"

  status=0
  { while true; do
    path=""
    rm -f "${tmp}/${consumer}.stdout" 2>/dev/null
    rm -f "${tmp}/${consumer}.stderr" 2>/dev/null
    if ! read -r -t 0.1 path; then
      continue
    fi
    if [[ -z ${path} ]]; then
      continue
    elif [[ ${path} == "<done>" ]]; then
      break
    else
      readarray -t tools < <(get_tools_for_file "path=${path}")
      if [[ ${#tools[@]} -eq 0 ]]; then
        # No tools for this file, skip it.
        echo 1 >>"${tmp}/${consumer}.skipped"
        continue
      fi
      process_file "path=${path}" "mode=${mode}" "${tools[@]}" 1>"${tmp}/${consumer}.stdout" 2>"${tmp}/${consumer}.stderr" || status=$?
      locked_echo "consumer=${consumer}" "lockfile=${tmp}/output.lock"
    fi
  done; } <"${tmp}/${consumer}.queue"

  return $status
}

produce() {
  local tmp num_jobs consumer found
  tmp="${1#tmp=}"
  num_jobs="${2#num_jobs=}"
  shift
  shift

  # Send work to consumers, round-robin.
  found=false
  consumer=1
  populate_find_args "$@"
  while read -r path; do
    found=true
    echo "${path}" >"${tmp}/${consumer}.queue"
    if [[ ${consumer} -eq ${num_jobs} ]]; then
      # Reset
      consumer=1
    else
      # Increment
      ((consumer++))
    fi
  done < <(find "${LINTBALL_FIND_ARGS[@]}" 2>"${tmp}/find.stderr")

  # Notify consumers that all paths have been enqueued
  for ((consumer = 1; consumer <= num_jobs; consumer++)); do
    echo "<done>" >"${tmp}/${consumer}.queue"
  done

  status=0
  if [[ ${found} == false ]]; then
    if [[ $# -gt 0 ]]; then
      for path in "$@"; do
        # path was provided explicitly, but `find` did not generate any paths
        if [[ -f ${path} ]]; then
          # no-op: file exists but is not handled
          if [[ -z "$(get_tools_for_file "path=$path")" ]]; then
            echo "File not handled: ${path@Q}."$'\n' >&2
          else
            echo "File not handled with current configuration: ${path@Q}."$'\n' >&2
          fi
        elif [[ -d ${path} ]]; then
          # no-op: directory is empty or has no files that are handled
          echo "No handled files found in directory ${path@Q}."$'\n' >&2
        else
          # error: passed an invalid path
          echo "File not found: ${path@Q}."$'\n' >&2
          status=1
        fi
      done
    elif [[ -n "$(cat "${tmp}/find.stderr")" ]]; then
      # something went wrong with `find` command
      echo "Error running find:" >&2
      cat "${tmp}/find.stderr" >&2
      echo >&2
      status=1
    else
      # no-op: current directory is empty or has no files that are handled
      echo "No handled files found in current directory."$'\n' >&2
    fi
  fi
  return $status
}

support_table() {
  cat <<EOF
Supported tools:
  | Language     |                                              Tools used |
  | :----------- | ------------------------------------------------------: |
  | bash         |                                       shellcheck, shfmt |
  | bats         |                                       shellcheck, shfmt |
  | CSS          |                                                prettier |
  | Cython       |                       autoflake, autopep8, docformatter |
  | GraphQL      |                                                prettier |
  | HTML         |                                                prettier |
  | JavaScript   |                                        eslint, prettier |
  | JSON         |                                                prettier |
  | JSX          |                                        eslint, prettier |
  | ksh          |                                       shellcheck, shfmt |
  | Markdown     |                                                prettier |
  | MDX          |                                                prettier |
  | mksh         |                                       shellcheck, shfmt |
  | package.json |                                   prettier-package-json |
  | pug          |                                     prettier/plugin-pug |
  | Python       | autoflake, autopep8, black, docformatter, isort, pylint |
  | SASS         |                                                prettier |
  | sh           |                                       shellcheck, shfmt |
  | TSX          |                                        eslint, prettier |
  | TypeScript   |                                        eslint, prettier |
  | XML          |                                     prettier/plugin-xml |
  | YAML         |                                      prettier, yamllint |

Detection methods:
  | Language     |                                           Detection |
  | :----------- | --------------------------------------------------: |
  | bash         |                         *.bash, #!/usr/bin/env bash |
  | bats         |                         *.bats, #!/usr/bin/env bats |
  | CSS          |                                               *.css |
  | Cython       |                                 *.pyx, *.pxd, *.pxi |
  | GraphQL      |                                           *.graphql |
  | HTML         |                                              *.html |
  | JavaScript   |                    *.js, *.cjs, #!/usr/bin/env node |
  | JSON         |                                              *.json |
  | JSX          |                                               *.jsx |
  | ksh          |                           *.ksh, #!/usr/bin/env ksh |
  | Markdown     |                                                *.md |
  | MDX          |                                               *.mdx |
  | mksh         |                         *.mksh, #!/usr/bin/env mksh |
  | package.json |                                        package.json |
  | pug          |                                               *.pug |
  | Python       |                  *.py, *.pyi, #!/usr/bin/env python |
  | SASS         |                                              *.scss |
  | sh           |                                     *.sh, #!/bin/sh |
  | TSX          |                                               *.tsx |
  | TypeScript   |                                                *.ts |
  | XML          |                                               *.xml |
  | YAML         |                                       *.yml, *.yaml |

EOF
}

usage() {
  cat <<EOF

█   █ █▄ █ ▀█▀ ██▄ ▄▀▄ █   █
█▄▄ █ █ ▀█  █  █▄█ █▀█ █▄▄ █▄▄
keep your entire project tidy with one command.

Usage:
  lintball [-h | -v]
  lintball [-c <path>] check [--since <commit>] [--jobs <n>] [paths …]
  lintball [-c <path>] fix [--since <commit>] [--jobs <n>] [paths …]
  lintball [-c <path>] install-githooks [-y | -n] [-p <path>]
  lintball [-c <path>] install-lintballrc [-y | -n] [-p <path>]
  lintball [-c <path>] install-tools [-a] [-p <path>] [ext …]
  lintball [-c <path>] clean-tools [-y]
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
                            as HEAD~1 or master.
    -j, --jobs <n>          The number of parallel jobs to run.
                              Default: the number of available CPUs.
  fix [paths …]             Recursively fix issues.
                              Exit 1 if unfixable issues.
    -s, --since <commit>    Fix only files changed since <commit>. This
                            includes both committed and uncommitted changes.
                            <commit> may be a commit hash or a committish, such
                            as HEAD~1 or master.
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
                            <path>. The tools will be installed in:
                            ${LINTBALL_DIR}/tools
    -p, --path <path>       The path to search for file types.
                              Default: working directory
    -a, --all               Install *all* tools.
  clean-tools               Remove all tools installed in:
                            ${LINTBALL_DIR}/tools
    -y, --yes               Skip prompt & remove all tools.
  pre-commit                Recursively fix issues on files that are fully
                            staged for commit. Recursively check for issues on
                            files that are partially staged for commit.
                              Exit 1 if unfixable issues on fully staged files.
                              Exit 1 if any issues on partially staged files.

Examples:
  \$ lintball check                       # Check working directory for issues.
  \$ lintball check --since HEAD~1        # Check working directory for issues
                                         # in all files changes since the commit
                                         # before last.
  \$ lintball check foo                   # Check the foo directory for issues.
  \$ lintball check foo.py                # Check the foo.py file for issues.
  \$ lintball fix                         # Fix issues in the working directory.
  \$ lintball -c foo/.lintballrc.json fix # Fix issues in the working directory
                                         # using the specified config.
  \$ lintball fix foo                     # Fix issues in the foo directory.
  \$ lintball fix foo.py                  # Fix issues in the foo.py file.
  \$ lintball install-githooks -p foo     # Install githooks in directory foo.
  \$ lintball install-githooks --yes      # Install a githooks config, replacing
                                         # any existing githooks config.
  \$ lintball install-lintballrc          # Install a default .lintballrc.json
                                         # in the working directory.
  \$ lintball install-lintballrc -p foo   # Install default .lintballrc.json in
                                         # directory foo.
  \$ lintball install-tools               # Autodetect tools for working
                                         # directory and install them.
  \$ lintball install-tools -p foo        # Autodetect tools for directory foo
                                         # and install them.
  \$ lintball install-tools --all         # Install all tools.
  \$ lintball clean-tools                 # Remove all installed tools.
  \$ lintball clean-tools --yes           # Remove all installed tools, skipping
                                        # prompt.
  \$ lintball install-tools py js yaml    # Install tools for checking Python,
                                         # JavaScript, & YAML.

EOF
}
