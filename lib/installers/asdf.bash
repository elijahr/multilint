# shellcheck disable=SC2154

configure_asdf() {
  if [[ ! -d "${LINTBALL_DIR}/tools/asdf" ]]; then
    git clone https://github.com/asdf-vm/asdf.git \
      --depth 1 \
      --branch "${ASDF_VERSION}" \
      "${LINTBALL_DIR}/tools/asdf"
    # disable `asdf update`
    touch "${LINTBALL_DIR}/tools/asdf/asdf_updates_disabled"
  fi
  # shellcheck disable=SC1091
  source "${LINTBALL_DIR}/tools/asdf/asdf.sh"
}
