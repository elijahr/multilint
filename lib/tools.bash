# shellcheck disable=SC2230

DOTS="..................................."

run_tool() {
  local tool mode path lang use status original cmd stdout stderr
  tool="${1#tool=}"
  mode="${2#mode=}"
  path="${3#path=}"
  if [[ $# -gt 3 ]]; then
    lang="${4#lang=}"
  else
    lang=""
  fi

  offset="${#tool}"
  use="LINTBALL_USE_$(echo "${tool//-/_}" | tr '[:lower:]' '[:upper:]')"
  if [[ ${!use} == "false" ]]; then
    printf " ↳ %s%s%s\n" "${tool}" "${DOTS:offset}" "off"
    return 0
  fi

  status=0
  IFS= read -r original < <(cat "${path}")
  IFS= read -r stdout < <(mktemp)
  IFS= read -r stderr < <(mktemp)

  readarray -t cmd < <(cmd_"${tool//-/_}" "mode=${mode}" "path=${path}" "lang=${lang}")

  # shellcheck disable=SC2068
  "${cmd[@]}" 1>"${stdout}" 2>"${stderr}" || status=$?

  if [[ "$mode" == "check" ]]; then
    if [[ ${status} -gt 0 ]]; then
      printf " ↳ %s%s%s\n" "${tool}" "${DOTS:offset}" "❌"
      cat "${stdout}" 2>/dev/null
      cat "${stderr}" 1>&2
    else
      printf " ↳ %s%s%s\n" "${tool}" "${DOTS:offset}" "ok"
    fi
  else
    # mode == fix
    if [[ "$(cat "${path}")" == "${original}" ]]; then
      if [[ ${status} -gt 0 ]] || {
        [[ "$(head -n1 "${stdout}" | head -c4)" == "--- " ]] &&
          [[ "$(head -n2 "${stdout}" | tail -n 1 | head -c4)" == "+++ " ]]
      }; then
        # Some error message or diff
        printf " ↳ %s%s%s\n" "${tool}" "${DOTS:offset}" "❌"
        cat "${stdout}" 2>/dev/null
        cat "${stderr}" 1>&2
        status=1
      else
        printf " ↳ %s%s%s\n" "${tool}" "${DOTS:offset}" "ok"
      fi
    else
      status=0
      printf " ↳ %s%s%s\n" "${tool}" "${DOTS:offset}" "wrote"
    fi
  fi
  rm "${stdout}"
  rm "${stderr}"
  return "${status}"
}

run_tool_clippy() {
  local mode path tool offset status cmd old dir stdout stderr
  mode="${1#mode=}"
  path="${2#path=}"

  tool="clippy"
  offset="${#tool}"
  if [[ ${LINTBALL_USE_CLIPPY} == "false" ]]; then
    printf " ↳ %s%s%s\n" "${tool}" "${DOTS:offset}" "off"
    return 0
  fi

  status=0
  IFS= read -r stdout < <(mktemp)
  IFS= read -r stderr < <(mktemp)

  readarray -t cmd < <(cmd_clippy "mode=${mode}")

  # path is always to a Cargo.toml file,
  # so cd to containing directory to run clippy
  old="${PWD}"
  IFS= read -r dir < <(dirname "${path}")
  status=0
  cd "${dir}" || return $?

  # shellcheck disable=SC2068
  "${cmd[@]}" 1>"${stdout}" 2>"${stderr}" || status=$?

  if [[ ${status} -gt 0 ]]; then
    # Some error message or diff
    printf " ↳ %s%s%s\n" "${tool}" "${DOTS:offset}" "❌"
    cat "${stdout}" 2>/dev/null
    cat "${stderr}" 1>&2
    status=1
  elif [[ "$(cat "$stdout")" =~ (^\s+Fixed) ]]; then
    printf " ↳ %s%s%s\n" "${tool}" "${DOTS:offset}" "wrote"
  else
    printf " ↳ %s%s%s\n" "${tool}" "${DOTS:offset}" "ok"
  fi
  rm "${stdout}"
  rm "${stderr}"
  cd "${old}" || return $?
  return "${status}"
}

run_tool_nimpretty() {
  local mode path tool offset use args cmd tmp patch stdout stderr status
  mode="${1#mode=}"
  path="${2#path=}"

  tool="nimpretty"
  offset="${#tool}"

  if [[ ${LINTBALL_USE_NIMPRETTY} == "false" ]]; then
    printf " ↳ %s%s%s\n" "${tool}" "${DOTS:offset}" "off"
    return 0
  fi

  declare -a args=()
  if [[ ${mode} == "write" ]]; then
    args+=("${LINTBALL_WRITE_ARGS_NIMPRETTY[@]}")
  else
    args+=("${LINTBALL_CHECK_ARGS_NIMPRETTY[@]}")
  fi

  IFS= read -r tmp < <(mktemp)
  IFS= read -r stdout < <(mktemp)
  IFS= read -r stderr < <(mktemp)
  status=0

  readarray -t cmd < <(interpolate \
    "tool" "nimpretty" \
    "lintball_dir" "${LINTBALL_DIR}" \
    "tmp" "${tmp}" \
    "path" "${path}" \
    -- "${args[@]}")

  # shellcheck disable=SC2068
  "${cmd[@]}" 1>"${stdout}" 2>"${stderr}" || status=$?

  if [[ ${status} -eq 0 ]]; then
    if [[ "$(cat "${tmp}")" == "$(cat "${path}")" ]]; then
      printf " ↳ %s%s%s\n" "${tool}" "${DOTS:offset}" "ok"
    else
      IFS= read -r patch < <(diff -u "${path}" "${tmp}")
      if [[ -n ${patch} ]]; then
        if [[ ${mode} == "write" ]]; then
          cat "${tmp}" >"${path}"
          printf " ↳ %s%s%s\n" "${tool}" "${DOTS:offset}" "wrote"
        else
          printf " ↳ %s%s%s\n" "${tool}" "${DOTS:offset}" "❌"
          echo "${patch}"
          status=1
        fi
      else
        printf " ↳ %s%s%s\n" "${tool}" "${DOTS:offset}" "❌"
        cat "${stdout}" 2>/dev/null
        cat "${stderr}" 1>&2
      fi
    fi
  else
    printf " ↳ %s%s%s\n" "${tool}" "${DOTS:offset}" "❌"
    cat "${stdout}" 2>/dev/null
    cat "${stderr}" 1>&2
  fi
  rm "${tmp}"
  rm "${stdout}"
  rm "${stderr}"
  return "${status}"
}

run_tool_prettier() {
  local mode path tool offset cmd stdout stderr status args patch original
  mode="${1#mode=}"
  path="${2#path=}"

  tool="prettier"
  offset="${#tool}"

  if [[ ${LINTBALL_USE_PRETTIER} == "false" ]]; then
    printf " ↳ %s%s%s\n" "${tool}" "${DOTS:offset}" "off"
    return 0
  fi

  IFS= read -r stdout < <(mktemp)
  IFS= read -r stderr < <(mktemp)
  IFS= read -r original < <(mktemp)
  status=0

  declare -a args=()
  if [[ ${mode} == "write" ]]; then
    args+=("${LINTBALL_WRITE_ARGS_PRETTIER[@]}")
  else
    args+=("${LINTBALL_CHECK_ARGS_PRETTIER[@]}")
  fi

  readarray -t cmd < <(interpolate \
    "tool" "prettier" \
    "lintball_dir" "${LINTBALL_DIR}" \
    "path" "$(absolutize_path "path=${path}")" \
    -- "${args[@]}")

  cp "${path}" "${original}"

  # shellcheck disable=SC2068
  "${cmd[@]}" 1>"${stdout}" 2>"${stderr}" || status=$?

  if [[ ${status} -eq 0 ]]; then
    if [[ ${mode} == "write" ]]; then
      if [[ "$(cat "${original}")" == "$(cat "${path}")" ]]; then
        printf " ↳ %s%s%s\n" "${tool}" "${DOTS:offset}" "ok"
      else
        printf " ↳ %s%s%s\n" "${tool}" "${DOTS:offset}" "wrote"
      fi
    else
      if [[ "$(cat "${path}")" == "$(cat "${stdout}")" ]]; then
        printf " ↳ %s%s%s\n" "${tool}" "${DOTS:offset}" "ok"
      else
        printf " ↳ %s%s%s\n" "${tool}" "${DOTS:offset}" "❌mode=${mode}"
        IFS= read -r patch < <(diff -u "${path}" "${stdout}")
        echo "${patch}"
        status=1
      fi
    fi
  else
    printf " ↳ %s%s%s\n" "${tool}" "${DOTS:offset}" "❌"
    cat "${stdout}" 2>/dev/null
    cat "${stderr}" 1>&2
  fi
  rm "${stdout}"
  rm "${stderr}"
  rm "${original}"
  return "${status}"
}

run_tool_eslint() {
  local mode path tool offset cmd tmp stdout stderr status args color
  mode="${1#mode=}"
  path="${2#path=}"

  tool="eslint"
  offset="${#tool}"

  if [[ ${LINTBALL_USE_ESLINT} == "false" ]]; then
    printf " ↳ %s%s%s\n" "${tool}" "${DOTS:offset}" "off"
    return 0
  fi

  IFS= read -r tmp < <(mktemp)
  IFS= read -r stdout < <(mktemp)
  IFS= read -r stderr < <(mktemp)
  status=0

  # show colors in output only if interactive shell
  color="--color"
  if [[ $- == *i* ]]; then
    color="--no-color"
  fi

  declare -a args=()
  if [[ ${mode} == "write" ]]; then
    args+=("${LINTBALL_WRITE_ARGS_ESLINT[@]}")
  else
    args+=("${LINTBALL_CHECK_ARGS_ESLINT[@]}")
  fi
  readarray -t cmd < <(interpolate \
    "tool" "eslint" \
    "lintball_dir" "${LINTBALL_DIR}" \
    "path" "$(absolutize_path "path=${path}")" \
    "color" "${color}" \
    "output_file" "${tmp}" \
    -- "${args[@]}")

  # shellcheck disable=SC2068
  "${cmd[@]}" 1>"${stdout}" 2>"${stderr}" || status=$?

  if [[ ${status} -eq 0 ]]; then
    if [[ ${mode} == "write" ]] &&
      [[ -n "$(cat "${tmp}")" ]] &&
      [[ "$(cat "${tmp}")" != "$(cat "${path}")" ]]; then
      printf " ↳ %s%s%s\n" "${tool}" "${DOTS:offset}" "wrote"
    else
      printf " ↳ %s%s%s\n" "${tool}" "${DOTS:offset}" "ok"
    fi
  else
    printf " ↳ %s%s%s\n" "${tool}" "${DOTS:offset}" "❌"
    cat "${stdout}" 2>/dev/null
    cat "${stderr}" 1>&2
  fi
  rm "${tmp}"
  rm "${stdout}"
  rm "${stderr}"
  return "${status}"
}

run_tool_shfmt() {
  local tool mode path lang status original cmd stdout stderr
  mode="${1#mode=}"
  path="${2#path=}"
  if [[ $# -gt 2 ]]; then
    lang="${3#lang=}"
  else
    lang=""
  fi
  tool="shfmt"

  offset="${#tool}"
  if [[ ${LINTBALL_USE_SHFMT} == "false" ]]; then
    printf " ↳ %s%s%s\n" "${tool}" "${DOTS:offset}" "off"
    return 0
  fi
  status=0
  IFS= read -r original < <(cat "${path}")
  IFS= read -r stdout < <(mktemp)
  IFS= read -r stderr < <(mktemp)

  readarray -t cmd < <(cmd_"${tool//-/_}" "mode=${mode}" "path=${path}" "lang=${lang}")

  # shellcheck disable=SC2068
  "${cmd[@]}" 1>"${stdout}" 2>"${stderr}" || status=$?

  if [[ "$mode" == "check" ]]; then
    if [[ ${status} -gt 0 ]]; then
      printf " ↳ %s%s%s\n" "${tool}" "${DOTS:offset}" "❌"
      cat "${stdout}" 2>/dev/null
      cat "${stderr}" 1>&2
    else
      printf " ↳ %s%s%s\n" "${tool}" "${DOTS:offset}" "ok"
    fi
  else
    # mode == fix
    if [[ "$(cat "${path}")" == "${original}" ]]; then
      if [[ ${status} -gt 0 ]] || {
        [[ "$(head -n1 "${stdout}" | head -c4)" == "--- " ]] &&
          [[ "$(head -n2 "${stdout}" | tail -n 1 | head -c4)" == "+++ " ]]
      }; then
        # Some error message or diff
        printf " ↳ %s%s%s\n" "${tool}" "${DOTS:offset}" "❌"
        cat "${stdout}" 2>/dev/null
        cat "${stderr}" 1>&2
        status=1
      else
        printf " ↳ %s%s%s\n" "${tool}" "${DOTS:offset}" "ok"
      fi
    else
      status=0
      printf " ↳ %s%s%s\n" "${tool}" "${DOTS:offset}" "wrote"
    fi
  fi
  rm "${stdout}"
  rm "${stderr}"
  return "${status}"
}

run_tool_shellcheck() {
  local mode path args cmd lang tool offset stdout stderr status color
  mode="${1#mode=}"
  path="${2#path=}"
  lang="${3#lang=}"

  tool="shellcheck"
  offset="${#tool}"

  if [[ ${LINTBALL_USE_SHELLCHECK} == "false" ]]; then
    printf " ↳ %s%s%s\n" "${tool}" "${DOTS:offset}" "off"
    return 0
  fi

  declare -a args=()
  if [[ ${mode} == "write" ]]; then
    args+=("${LINTBALL_WRITE_ARGS_SHELLCHECK[@]}")
  else
    args+=("${LINTBALL_CHECK_ARGS_SHELLCHECK[@]}")
  fi

  IFS= read -r stdout < <(mktemp)
  IFS= read -r stderr < <(mktemp)
  IFS= read -r patchfile < <(mktemp)
  IFS= read -r patcherr < <(mktemp)
  status=0

  # show colors in output only if interactive shell
  color="never"
  if [[ $- == *i* ]]; then
    color="always"
  fi

  readarray -t cmd < <(interpolate \
    "tool" "shellcheck" \
    "lintball_dir" "${LINTBALL_DIR}" \
    "format" "tty" \
    "color" "${color}" \
    "lang" "${lang}" \
    "path" "${path}" \
    -- "${args[@]}")

  # shellcheck disable=SC2068
  "${cmd[@]}" 1>"${stdout}" 2>"${stderr}" || status=$?

  if [[ ${status} -eq 0 ]]; then
    # File has no issues
    printf " ↳ %s%s%s\n" "${tool}" "${DOTS:offset}" "ok"
  else
    # stdout contains the tool results
    # stderr contains an error message
    if [[ ${mode} == "write" ]] && [[ -n "$(cat "${stdout}" 2>/dev/null)" ]]; then
      # patchable, so generate a patchfile and apply it
      readarray -t cmd < <(interpolate \
        "tool" "shellcheck" \
        "lintball_dir" "${LINTBALL_DIR}" \
        "format" "diff" \
        "color" "never" \
        "lang" "${lang}" \
        "path" "${path}" \
        -- "${args[@]}")

      # shellcheck disable=SC2068
      "${cmd[@]}" 1>"${patchfile}" 2>"${patcherr}" || true

      if [[ -n "$(cat "${patchfile}")" ]]; then
        # Fix patchfile
        sed -i '' 's/^--- a\/\.\//--- a\//' "${patchfile}"
        sed -i '' 's/^+++ b\/\.\//+++ b\//' "${patchfile}"
        git apply "${patchfile}" 1>/dev/null
        printf " ↳ %s%s%s\n" "${tool}" "${DOTS:offset}" "wrote"
        status=0
      else
        if [[ -n "$(cat "${patcherr}")" ]]; then
          # not patchable, show output from initial shellcheck run
          printf " ↳ %s%s%s\n" "${tool}" "${DOTS:offset}" "❌"
          cat "${stdout}"
        else
          printf " ↳ %s%s%s\n" "${tool}" "${DOTS:offset}" "unknown error"
        fi
      fi
    else
      # not patchable, show error
      printf " ↳ %s%s%s\n" "${tool}" "${DOTS:offset}" "❌"
      cat "${stdout}" 2>/dev/null
      cat "${stderr}" 1>&2
    fi
  fi
  rm "${stdout}"
  rm "${stderr}"
  rm "${patchfile}"
  rm "${patcherr}"
  return "${status}"
}

run_tool_uncrustify() {
  local mode path lang tool offset args cmd patch stdout stderr status
  mode="${1#mode=}"
  path="${2#path=}"
  lang="${3#lang=}"

  tool="uncrustify"
  offset="${#tool}"

  if [[ ${LINTBALL_USE_UNCRUSTIFY} == "false" ]]; then
    printf " ↳ %s%s%s\n" "${tool}" "${DOTS:offset}" "off"
    return 0
  fi

  declare -a args=()
  if [[ ${mode} == "write" ]]; then
    args+=("${LINTBALL_WRITE_ARGS_UNCRUSTIFY[@]}")
  else
    args+=("${LINTBALL_CHECK_ARGS_UNCRUSTIFY[@]}")
  fi

  IFS= read -r stdout < <(mktemp)
  IFS= read -r stderr < <(mktemp)
  status=0

  readarray -t cmd < <(interpolate \
    "tool" "uncrustify" \
    "lintball_dir" "${LINTBALL_DIR}" \
    "lang" "${lang}" \
    "path" "${path}" \
    -- "${args[@]}")

  # shellcheck disable=SC2068
  "${cmd[@]}" 1>"${stdout}" 2>"${stderr}" || status=$?

  if [[ ${status} -eq 0 ]]; then
    if [[ "$(cat "${stdout}")" == "$(cat "${path}")" ]]; then
      printf " ↳ %s%s%s\n" "${tool}" "${DOTS:offset}" "ok"
    else
      IFS= read -r patch < <(diff -u "${path}" "${stdout}")
      if [[ -n ${patch} ]]; then
        if [[ ${mode} == "write" ]]; then
          cat "${stdout}" >"${path}"
          printf " ↳ %s%s%s\n" "${tool}" "${DOTS:offset}" "wrote"
        else
          printf " ↳ %s%s%s\n" "${tool}" "${DOTS:offset}" "❌"
          echo "${patch}"
          status=1
        fi
      else
        printf " ↳ %s%s%s\n" "${tool}" "${DOTS:offset}" "❌"
        cat "${stdout}" 2>/dev/null
        cat "${stderr}" 1>&2
      fi
    fi
  else
    printf " ↳ %s%s%s\n" "${tool}" "${DOTS:offset}" "❌"
    cat "${stderr}" 1>&2
  fi
  rm "${stdout}"
  rm "${stderr}"
  return "${status}"
}
