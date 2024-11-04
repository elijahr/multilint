cmd_autoflake() {
  local mode path args
  mode="${1#mode=}"
  path="${2#path=}"
  declare -a args=()
  if [[ ${mode} == "write" ]]; then
    args+=("${LINTBALL_WRITE_ARGS_AUTOFLAKE[@]}")
  else
    args+=("${LINTBALL_CHECK_ARGS_AUTOFLAKE[@]}")
  fi
  interpolate \
    "tool" "autoflake" \
    "lintball_dir" "${LINTBALL_DIR}" \
    "path" "${path}" \
    -- "${args[@]}"
}

cmd_autopep8() {
  local mode path args
  mode="${1#mode=}"
  path="${2#path=}"
  declare -a args=()
  if [[ ${mode} == "write" ]]; then
    args+=("${LINTBALL_WRITE_ARGS_AUTOPEP8[@]}")
  else
    args+=("${LINTBALL_CHECK_ARGS_AUTOPEP8[@]}")
  fi
  interpolate \
    "tool" "autopep8" \
    "lintball_dir" "${LINTBALL_DIR}" \
    "path" "${path}" \
    -- "${args[@]}"
}

cmd_black() {
  local mode path args
  mode="${1#mode=}"
  path="${2#path=}"
  declare -a args=()
  if [[ ${mode} == "write" ]]; then
    args+=("${LINTBALL_WRITE_ARGS_BLACK[@]}")
  else
    args+=("${LINTBALL_CHECK_ARGS_BLACK[@]}")
  fi
  interpolate \
    "tool" "black" \
    "lintball_dir" "${LINTBALL_DIR}" \
    "path" "${path}" \
    -- "${args[@]}"
}

cmd_docformatter() {
  local mode path args
  mode="${1#mode=}"
  path="${2#path=}"

  declare -a args=()
  if [[ ${mode} == "write" ]]; then
    args+=("${LINTBALL_WRITE_ARGS_DOCFORMATTER[@]}")
  else
    args+=("${LINTBALL_CHECK_ARGS_DOCFORMATTER[@]}")
  fi
  interpolate \
    "tool" "docformatter" \
    "lintball_dir" "${LINTBALL_DIR}" \
    "path" "${path}" \
    -- "${args[@]}"
}

cmd_isort() {
  local mode path args
  mode="${1#mode=}"
  path="${2#path=}"

  declare -a args=()
  if [[ ${mode} == "write" ]]; then
    args+=("${LINTBALL_WRITE_ARGS_ISORT[@]}")
  else
    args+=("${LINTBALL_CHECK_ARGS_ISORT[@]}")
  fi
  interpolate \
    "tool" "isort" \
    "lintball_dir" "${LINTBALL_DIR}" \
    "path" "${path}" \
    -- "${args[@]}"
}

cmd_prettier() {
  local mode path args
  mode="${1#mode=}"
  path="${2#path=}"
  declare -a args=()
  if [[ ${mode} == "write" ]]; then
    args+=("${LINTBALL_WRITE_ARGS_PRETTIER[@]}")
  else
    args+=("${LINTBALL_CHECK_ARGS_PRETTIER[@]}")
  fi
  interpolate \
    "tool" "prettier" \
    "lintball_dir" "${LINTBALL_DIR}" \
    "path" "$(absolutize_path "path=${path}")" \
    -- "${args[@]}"
}

cmd_eslint() {
  local mode path args
  mode="${1#mode=}"
  path="${2#path=}"
  declare -a args=()
  if [[ ${mode} == "write" ]]; then
    args+=("${LINTBALL_WRITE_ARGS_PRETTIER[@]}")
  else
    args+=("${LINTBALL_CHECK_ARGS_PRETTIER[@]}")
  fi
  interpolate \
    "tool" "eslint" \
    "lintball_dir" "${LINTBALL_DIR}" \
    "path" "$(absolutize_path "path=${path}")" \
    -- "${args[@]}"
}

cmd_pylint() {
  local mode path format args
  mode="${1#mode=}"
  path="${2#path=}"

  # show colors in output only if interactive shell
  format="text"
  if [[ $- == *i* ]]; then
    format="colorized"
  fi

  declare -a args=()
  if [[ ${mode} == "write" ]]; then
    args+=("${LINTBALL_WRITE_ARGS_PYLINT[@]}")
  else
    args+=("${LINTBALL_CHECK_ARGS_PYLINT[@]}")
  fi
  interpolate \
    "tool" "pylint" \
    "lintball_dir" "${LINTBALL_DIR}" \
    "format" "${format}" \
    "path" "${path}" \
    -- "${args[@]}"
}

cmd_shfmt() {
  local mode path lang args
  mode="${1#mode=}"
  path="${2#path=}"
  lang="${3#lang=}"

  declare -a args=()
  if [[ ${mode} == "write" ]]; then
    args+=("${LINTBALL_WRITE_ARGS_SHFMT[@]}")
  else
    args+=("${LINTBALL_CHECK_ARGS_SHFMT[@]}")
  fi
  interpolate \
    "tool" "shfmt" \
    "lintball_dir" "${LINTBALL_DIR}" \
    "lang" "${lang}" \
    "path" "${path}" \
    -- "${args[@]}"
}

cmd_yamllint() {
  local mode path format args
  mode="${1#mode=}"
  path="${2#path=}"

  # show colors in output only if interactive shell
  format="auto"
  if [[ $- == *i* ]]; then
    format="colored"
  fi
  declare -a args=()
  if [[ ${mode} == "write" ]]; then
    args+=("${LINTBALL_WRITE_ARGS_YAMLLINT[@]}")
  else
    args+=("${LINTBALL_CHECK_ARGS_YAMLLINT[@]}")
  fi
  interpolate \
    "tool" "yamllint" \
    "lintball_dir" "${LINTBALL_DIR}" \
    "format" "${format}" \
    "path" "${path}" \
    -- "${args[@]}"
}
