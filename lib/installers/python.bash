# shellcheck disable=SC2154

install_python() {
  local old status
  if [[ $USE_ASDF == "true" ]]; then
    configure_asdf
    if [[ ! -d "${ASDF_DATA_DIR}/installs/python/${ASDF_PYTHON_VERSION}" ]]; then
      asdf plugin-add python || true
      asdf install python
      asdf reshim
    fi
  fi
  status=0
  old="${PWD}"
  cd "${LINTBALL_DIR}/tools" || return $?
  pip install -r pip-requirements.txt --no-cache-dir || status=$?
  if [[ $USE_ASDF == "true" ]]; then
    asdf reshim
  fi
  cd "${old}" || return $?
  return "${status}"
}
