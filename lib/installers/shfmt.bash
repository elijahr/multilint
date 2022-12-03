ASDF_SHFMT_VERSION=3.5.1
export ASDF_SHFMT_VERSION

install_shfmt() {
  if [ ! -d "${ASDF_DATA_DIR}/installs/shfmt/${ASDF_SHFMT_VERSION}" ]; then
    configure_asdf || return $?
    asdf plugin-add shfmt || true
    asdf install shfmt || return $?
    asdf reshim
  fi
}