# shellcheck disable=SC2154

install_shellcheck() {
  if [[ $USE_ASDF == "true" ]]; then
    if [[ ! -d "${ASDF_DATA_DIR}/installs/shellcheck/${ASDF_SHELLCHECK_VERSION}" ]]; then
      configure_asdf
      asdf plugin-add shellcheck || true
      asdf install shellcheck
      asdf reshim
    fi
  fi
}
