# shellcheck disable=SC2154

install_nodejs() {
  local old status
  configure_asdf
  if [[ ! -d "${ASDF_DATA_DIR}/installs/nodejs/${ASDF_NODEJS_VERSION}" ]]; then
    asdf plugin-add nodejs || true
    asdf install nodejs
    asdf reshim
  fi
  old="${PWD}"
  cd "${LINTBALL_DIR}/tools" || return $?
  status=0
  npm ci || status=$?
  npm cache clean --force || status=$?
  asdf reshim || status=$?
  cd "${old}" || return $?
  return "${status}"
}
