absolutize_path() {
  local path
  path=${1#path=}
  echo "$(cd "$(dirname "${path}")" && pwd)/$(basename "${path}")"
}

has_shebang() {
  local two_bytes
  IFS= read -n2 -rd '' two_bytes <"$1"
  [ "$two_bytes" = '#!' ]
}

populate_find_args() {
  local normalized_path

  LINTBALL_FIND_ARGS=("-L")

  for path in "$@"; do
    IFS= read -r normalized_path < <(normalize_path "path=${path}")
    if [[ -n ${normalized_path} ]]; then
      LINTBALL_FIND_ARGS+=("${normalized_path}")
    fi
  done

  if [[ ${#LINTBALL_FIND_ARGS[@]} -eq 1 ]]; then
    # all args were whitespace only or no path was provided, so default to current dir
    LINTBALL_FIND_ARGS+=(".")
  fi

  LINTBALL_FIND_ARGS+=("-type" "f")

  for ignore in "${LINTBALL_IGNORE_GLOBS[@]}"; do
    if [[ -n ${ignore} ]]; then
      LINTBALL_FIND_ARGS+=("-a" "(" "-not" "-path" "${ignore}" ")")
    fi
  done

  LINTBALL_FIND_ARGS+=("-a" "(")
  LINTBALL_FIND_ARGS+=("(")

  # files with handled extensions
  for i in "${!LINTBALL_HANDLED_EXTENSIONS[@]}"; do
    if [[ ${i} -gt 0 ]]; then
      LINTBALL_FIND_ARGS+=("-o")
    fi
    LINTBALL_FIND_ARGS+=("-name" "*.${LINTBALL_HANDLED_EXTENSIONS[$i]}")
  done
  LINTBALL_FIND_ARGS+=(")")

  # exclude files without extensions
  LINTBALL_FIND_ARGS+=("-o" "(" "-not" "(" "-name" "*.*" ")" ")")
  LINTBALL_FIND_ARGS+=(")")

  LINTBALL_FIND_ARGS+=("-print")
}

config_find() {
  local path

  if [[ $# -eq 0 ]]; then
    IFS= read -r path < <(pwd)
  else
    IFS= read -r path < <(normalize_path "$1")
  fi

  if [[ -f ${path} ]]; then
    echo "${path}"
    return 0
  fi

  if ! [[ -d ${path} ]]; then
    echo "Not a valid path arg: ${path}" >&2
    return 1
  fi

  path="$(
    cd "$path" || exit
    pwd
  )"

  # Traverse up the directory tree looking for .lintballrc.json
  while true; do
    if [[ -f "${path}/.lintballrc.json" ]] || [[ -s "${path}/.lintballrc" ]]; then
      echo "${path}/.lintballrc.json"
      return 0
    else
      IFS= read -r path < <(dirname "${path}")
    fi
    if [[ ${path} == "/" ]]; then
      break
    fi
  done

  return 1
}

config_load() {
  local path name value line lintballrc_version tool tool_upper tmparray tmpstring arrayref
  if [[ -z ${1:-} ]]; then
    echo "config_load: missing path arg" >&2
    return 1
  fi
  path="${1#path=}"
  IFS= read -r path < <(normalize_path "path=${path}")

  if [[ ! -f ${path} ]]; then
    echo "config_load: No config file at ${path}" >&2
    return 1
  fi

  if ! command -v jq >/dev/null 2>&1; then
    echo "jq is required to parse config files; install jq" >&2
    return 1
  fi

  # Verify that the config file matches LINTBALLRC_VERSION
  IFS= read -r lintballrc_version < <(jq --raw-output "try .lintballrc_version catch null" 2>/dev/null <"${path}") || true
  # shellcheck disable=SC2153
  if [[ ${lintballrc_version} != "${LINTBALLRC_VERSION}" ]]; then
    echo "Cannot use config file ${path@Q}: expected lintballrc_version \"${LINTBALLRC_VERSION}\" but found \"${lintballrc_version}\"" >&2
    return 1
  fi

  for tool in "${LINTBALL_ALL_TOOLS[@]}"; do
    tool_upper="${tool^^}"
    tool_upper="${tool_upper//[^a-zA-Z0-9 ]/_}"

    IFS= readarray -t tmparray < <(jq --raw-output "try .write_args.\"${tool}\"[] catch \"<empty>\"" 2>/dev/null <"${path}")
    # shellcheck disable=SC2128
    if [[ ${tmparray} != "<empty>" ]]; then
      # overwrite the write args array for this tool.
      # declare the dynamic-named global var as an array,
      # then create a static-named pointer to it in order
      # to assign a value. this is a workaround for bash
      # limitations. See https://stackoverflow.com/questions/53987310/how-to-copy-an-array-to-a-new-array-with-dynamic-name
      # shellcheck disable=SC2178
      declare -n arrayref="LINTBALL_WRITE_ARGS_${tool_upper}"
      # shellcheck disable=SC2034
      arrayref=("${tmparray[@]}")
    fi
    IFS= readarray -t tmparray < <(jq --raw-output "try .check_args.\"${tool}\"[] catch \"<empty>\"" 2>/dev/null <"${path}")
    # shellcheck disable=SC2128
    if [[ ${tmparray} != "<empty>" ]]; then
      # overwrite the write args array for this tool.
      # declare the dynamic-named global var as an array,
      # then create a static-named pointer to it in order
      # to assign a value. this is a workaround for bash
      # limitations. See https://stackoverflow.com/questions/53987310/how-to-copy-an-array-to-a-new-array-with-dynamic-name
      # shellcheck disable=SC2178
      declare -n arrayref="LINTBALL_CHECK_ARGS_${tool_upper}"
      # shellcheck disable=SC2034
      arrayref=("${tmparray[@]}")
    fi
    IFS= read -r tmpstring < <(jq --raw-output "try .use.\"${tool}\" catch null" 2>/dev/null <"${path}")
    if [ -n "${tmpstring}" ]; then
      # overwrite the use value for this tool
      name="LINTBALL_USE_${tool_upper}"
      # shellcheck disable=SC2229
      read -r "${name}" <<<"${tmpstring}"
      # shellcheck disable=SC2163
      export "${name}"
    fi
  done

  IFS= readarray -t tmparray < <(jq --raw-output 'try .ignores[] catch "<empty>"' 2>/dev/null <"${path}")
  # shellcheck disable=SC2128
  if [[ ${tmparray} != "<empty>" ]]; then
    # overwrite the global LINTBALL_IGNORE_GLOBS array
    LINTBALL_IGNORE_GLOBS=("${tmparray[@]}")
  fi
  IFS= readarray -t tmparray < <(jq --raw-output 'try ."ignores+="[] catch "<empty>"' 2>/dev/null <"${path}")
  # shellcheck disable=SC2128
  if [[ ${tmparray} != "<empty>" ]]; then
    # append to the global LINTBALL_IGNORE_GLOBS array
    LINTBALL_IGNORE_GLOBS+=("${tmparray[@]}")
  fi
  IFS= read -r tmpstring < <(jq --raw-output 'try .num_jobs catch null' 2>/dev/null <"${path}")
  if [[ ${tmpstring} != "null" ]]; then
    LINTBALL_NUM_JOBS="${tmpstring}"
    export LINTBALL_NUM_JOBS
  fi
}

confirm_copy() {
  local src dest answer
  src="${1#src=}"
  dest="${2#dest=}"
  answer="${3#answer=}"
  if [ -d "${src}" ] || [ -d "${dest}" ]; then
    echo >&2
    echo "Source and destination must be file paths, not directories." >&2
    echo >&2
    return 1
  fi
  if [ -f "${dest}" ]; then
    if [ -z "${answer}" ]; then
      if ! read -rp "${dest//${HOME}/"~"} exists. Replace? [y/N] " answer; then
        echo "${dest//${HOME}/"~"} exists. Pass --yes to replace." >&2
        return 1
      fi
    fi
    case "$answer" in
      [yY]*) ;;
      *)
        echo >&2
        echo "File exists, cancelled: ${dest}" >&2
        echo >&2
        return 1
        ;;
    esac
  fi
  if [ ! -d "$(dirname "${dest}")" ]; then
    mkdir -p "$(dirname "${dest}")"
  fi
  cp -Rf "$src" "$dest"
  echo "Copied ${src//${HOME}/"~"} → ${dest//${HOME}/"~"}"
}

documentation_link() {
  echo "Additional documentation can be found in ${LINTBALL_DIR}/README.md"
  echo "or at https://github.com/elijahr/lintball"
  echo
}

find_git_dir() {
  local dir
  # Traverse up the directory tree looking for .git
  dir="${1#dir=}"
  while [ "$dir" != "/" ]; do
    if [ -d "${dir}/.git" ]; then
      echo "${dir}/.git"
      break
    else
      IFS= read -r dir < <(dirname "${dir}")
    fi
  done
}

get_fully_staged_paths() {
  local line
  while read -r line; do
    # shellcheck disable=SC2143
    if [[ -z "$(git diff --name-only | grep -F "${line}")" ]]; then
      if [[ -f ${line} ]]; then
        # path exists, is staged and has no unstaged changes
        echo "${line}"
      fi
    fi
  done < <(git diff --name-only --cached | sort)
}

get_installer_for_tool() {
  local tool
  tool="${1#tool=}"
  case "$tool" in
    autoflake | autopep8 | black | docformatter | isort | yamllint)
      echo "install_python"
      ;;
    prettier | eslint) echo "install_nodejs" ;;
    shfmt) echo "install_shfmt" ;;
    *) echo "" ;;
  esac
}

get_lang_shellcheck() {
  local extension
  extension="${1#extension=}"
  case "$extension" in
    mksh) echo "ksh" ;;
    *) echo "$extension" ;;
  esac
}

get_lang_shfmt() {
  local extension
  extension="${1#extension=}"
  case "$extension" in
    ksh) echo "mksh" ;;
    sh) echo "posix" ;;
    *) echo "$extension" ;;
  esac
}

get_paths_changed_since_commit() {
  local commit
  commit="${1#commit=}"
  (
    git diff --name-only "$commit"
    git ls-files . --exclude-standard --others
  ) | sort | uniq | xargs -I{} sh -c "test -f '{}' && echo '{}'"
}

get_shebang() {
  local path
  path="${1#path=}"
  if has_shebang "${path}"; then
    head -n1 "$path"
  fi
}

get_tools_for_file() {
  local path extension

  path="${1#path=}"
  IFS= read -r path < <(normalize_path "path=${path}")
  IFS= read -r extension < <(normalize_extension "path=${path}")

  case "$extension" in
    css | graphql | html | jade | json | md | mdx | pug | scss | xml)
      if [[ $LINTBALL_USE_PRETTIER != "false" ]]; then
        echo "prettier"
      fi
      ;;
    bash | bats | ksh | mksh | sh)
      if [[ $LINTBALL_USE_SHFMT != "false" ]]; then
        echo "shfmt"
      fi
      if [[ $LINTBALL_USE_SHELLCHECK != "false" ]]; then
        echo "shellcheck"
      fi
      ;;
    cjs | js | jsx | ts | tsx)
      if [[ $LINTBALL_USE_PRETTIER != "false" ]]; then
        echo "prettier"
      fi
      if [[ $LINTBALL_USE_ESLINT != "false" ]]; then
        echo "eslint"
      fi
      ;;
    py)
      if [[ $LINTBALL_USE_DOCFORMATTER != "false" ]]; then
        echo "docformatter"
      fi
      if [[ $LINTBALL_USE_AUTOPEP8 != "false" ]]; then
        echo "autopep8"
      fi
      if [[ $LINTBALL_USE_AUTOFLAKE != "false" ]]; then
        echo "autoflake"
      fi
      if [[ $LINTBALL_USE_ISORT != "false" ]]; then
        echo "isort"
      fi
      if [[ $LINTBALL_USE_BLACK != "false" ]]; then
        echo "black"
      fi
      if [[ $LINTBALL_USE_PYLINT != "false" ]]; then
        echo "pylint"
      fi
      ;;
    pyi)
      if [[ $LINTBALL_USE_DOCFORMATTER != "false" ]]; then
        echo "docformatter"
      fi
      if [[ $LINTBALL_USE_AUTOPEP8 != "false" ]]; then
        echo "autopep8"
      fi
      if [[ $LINTBALL_USE_AUTOFLAKE != "false" ]]; then
        echo "autoflake"
      fi
      if [[ $LINTBALL_USE_PYLINT != "false" ]]; then
        echo "pylint"
      fi
      ;;
    pyx | pxd | pxi)
      if [[ $LINTBALL_USE_DOCFORMATTER != "false" ]]; then
        echo "docformatter"
      fi
      if [[ $LINTBALL_USE_AUTOPEP8 != "false" ]]; then
        echo "autopep8"
      fi
      if [[ $LINTBALL_USE_AUTOFLAKE != "false" ]]; then
        echo "autoflake"
      fi
      ;;
    yml)
      if [[ $LINTBALL_USE_PRETTIER != "false" ]]; then
        echo "prettier"
      fi
      if [[ $LINTBALL_USE_YAMLLINT != "false" ]]; then
        echo "yamllint"
      fi
      ;;
  esac
}

interpolate() {
  local vars key value arg
  declare -A vars=()
  while [ "$#" -ge 1 ]; do
    key=$1
    shift
    if [[ ${key} == "--" ]]; then
      # begin processing arguments
      break
    fi
    value="$1"
    shift
    vars[$key]="$value"
  done
  for arg in "$@"; do
    for key in "${!vars[@]}"; do
      value="${vars[${key}]}"
      arg="${arg//'{{ '${key}' }}'/${value}}"
      arg="${arg//'{{'${key}'}}'/${value}}"
    done
    if [[ $arg =~ (\{\{[ ]*[a-zA-Z0-9_-]+[ ]*\}\}) ]]; then
      echo "Unknown variable in arg ${arg@Q}" >&2
      echo "Valid variables:" >&2
      for key in "${!vars[@]}"; do
        echo "- {{ ${key} }}" >&2
      done
      return 1
    fi
    echo "$arg"
  done
}

normalize_extension() {
  local path lang filename extension
  path="${1#path=}"

  # Check for `# lintball lang=foo` overrides
  lang=""
  if [ -e "$path" ]; then
    IFS= read -r lang < <(grep '^# lintball lang=' "${path}" | sed 's/^# lintball lang=//' | tr '[:upper:]' '[:lower:]') || true
  fi

  case "$lang" in
    cython) extension="pyx" ;;
    javascript) extension="js" ;;
    markdown) extension="md" ;;
    python) extension="py" ;;
    typescript) extension="ts" ;;
    yaml) extension="yml" ;;
    *)
      if [ -n "${lang}" ]; then
        extension="${lang}"
      else
        IFS= read -r filename < <(basename "${path}")
        extension="${filename##*.}"
      fi
      ;;
  esac

  case "$extension" in
    bash | bats | cjs | css | graphql | \
      html | jade | js | json | jsx | ksh | md | mdx | \
      mksh | pug | pxd | pxi | py | pyi | pyx | scss | \
      ts | tsx | xml | yml)
      echo "$extension"
      ;;
    sh)
      # Inspect shebang to get actual shell interpreter
      case "$(get_shebang "path=${path}")" in
        *bash) echo "bash" ;;
        *mksh) echo "mksh" ;;
        *ksh) echo "ksh" ;;
        *) echo "sh" ;;
      esac
      ;;
    yaml) echo "yml" ;;
    *)
      # File has no extension, inspect shebang to get interpreter
      case "$(get_shebang "path=${path}")" in
        */bin/sh) echo "sh" ;;
        *bash) echo "bash" ;;
        *bats) echo "bats" ;;
        *ksh) echo "ksh" ;;
        *node* | *deno*) echo "js" ;;
        *python*) echo "py" ;;
      esac
      ;;
  esac
}

normalize_path() {
  local path
  path="${1#path=}"

  # Strip redundant slashes
  while [[ $path =~ \/\/ ]]; do
    path="${path//\/\//\/}"
  done

  # Strip trailing slash, leading/trailing whitespace
  IFS= read -r path < <(echo "${path}" | sed 's/\/$//' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

  if [[ $path =~ ^[^/\.] ]]; then
    # ensure relative paths (foo/bar) are prepended with ./ (./foo/bar) to
    # ensure that */foo/* ignore patterns will match.
    echo "./$path"
  else
    echo "$path"
  fi
}

prettify_path() {
  local path
  path="${1#path=}"
  # - strip leading ./ from path
  path="${path#./}"
  if [[ ${path} =~ ^"${HOME}"(.*) ]]; then
    # - swap ${HOME} for ~ in path
    path="~${BASH_REMATCH[1]}"
  fi
  echo "${path}"
}

# shellcheck disable=SC2120
parse_version() {
  local text
  text="${1#text=}"
  echo "$text" |
    grep '[0-9]\{1,\}\.[0-9]\{1,\}\.[0-9]\{1,\}' |
    head -n 1 |
    sed 's/.*\([0-9]\{1,\}\.[0-9]\{1,\}\.[0-9]\{1,\}\).*/\1/'
}

parse_major_version() {
  parse_version "$@" |
    sed 's/\.[0-9]\{1,\}\.[0-9]\{1,\}$//'
}
