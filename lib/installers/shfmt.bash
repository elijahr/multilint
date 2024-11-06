# shellcheck disable=SC2154

install_shfmt() {
  if [[ $USE_ASDF == "true" ]]; then
    if [[ ! -d "${ASDF_DATA_DIR}/installs/shfmt/${ASDF_SHFMT_VERSION}" ]]; then
      configure_asdf
      asdf plugin-add shfmt || true
      asdf install shfmt
      asdf reshim
    fi
  fi
}
