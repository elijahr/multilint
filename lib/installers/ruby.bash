# shellcheck disable=SC2154

BUNDLE_GEMFILE="${LINTBALL_DIR}/tools/Gemfile"
export BUNDLE_GEMFILE

install_ruby() {
  local old status openssl_prefix
  configure_asdf
  status=0
  if [[ ! -d "${ASDF_DATA_DIR}/installs/ruby/${ASDF_RUBY_VERSION}" ]]; then
    asdf plugin-add ruby || true
    if [ -n "$(command -v uname)" ] && [[ "$(uname -s)" == "Darwin" ]]; then
      if [ -z "$(command -v brew)" ]; then
        echo "Ruby needs Homebrew to install. Visit https://brew.sh" >&2
        return 1
      fi
      openssl_prefix="$(brew --prefix openssl@3 || true)"
      if [ -z "$openssl_prefix" ]; then
        echo "Ruby needs a compatible OpenSSL installed. Run:" >&2
        echo "" >&2
        echo "    brew install  openssl@3" >&2
        return 1
      fi
      export RUBY_CONFIGURE_OPTS="--with-openssl-dir=$openssl_prefix"
    fi
    LDFLAGS="" asdf install ruby
    asdf reshim
  fi
  old="${PWD}"
  cd "${LINTBALL_DIR}/tools" || return $?
  gem install bundler &&
    bundle config set --local deployment 'false' &&
    bundle install &&
    gem sources --clear-all ||
    status=$?
  asdf reshim
  cd "${old}" || return $?
  return "${status}"
}
