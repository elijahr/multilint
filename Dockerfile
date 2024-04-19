# syntax=docker/dockerfile:1

# Dockerfile optimized to build lintball's dependencies in parallel and pare
# down to the smallest possible output image.


## <base image> ###############################################################
FROM --platform=$TARGETPLATFORM debian:bookworm-slim as lintball-base
ENV LINTBALL_DIR=/lintball

# Install minimal deps as quickly as possible
RUN echo 'APT::Install-Suggests "0";' >> /etc/apt/apt.conf.d/99no-install-recommends && \
    echo 'APT::Install-Recommends "0";' >> /etc/apt/apt.conf.d/99no-install-recommends && \
    apt update && apt install -y gnupg && \
    echo "deb http://ppa.launchpad.net/apt-fast/stable/ubuntu jammy main" >> /etc/apt/sources.list.d/apt-fast.list && \
    echo "deb-src http://ppa.launchpad.net/apt-fast/stable/ubuntu jammy main" >> /etc/apt/sources.list.d/apt-fast.list && \
    apt-key adv --keyserver keyserver.ubuntu.com --recv-keys A2166B8DE8BDC3367D1901C11EE2FF37CA8DA16B && \
    echo debconf apt-fast/maxdownloads string 16 | debconf-set-selections && \
    echo debconf apt-fast/dlflag boolean true | debconf-set-selections && \
    echo debconf apt-fast/aptmanager string apt-get | debconf-set-selections && \
    echo "deb-src http://deb.debian.org/debian bookworm main" >> /etc/apt/sources.list && \
    apt update && apt install -y apt-fast && apt-fast install -y \
      build-essential bzip2 ca-certificates cmake coreutils curl gcc git libbz2-1.0 libbz2-dev libc6-dev libffi-dev libreadline-dev \
      libssl3 libssl-dev libyaml-0-2 libyaml-dev lzma make ncurses-dev openssh-client openssl perl procps uuid xz-utils zlib1g zlib1g-dev && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /tmp/* && \
    rm -rf /var/tmp/*

RUN mkdir -p "${LINTBALL_DIR}/configs" && \
    mkdir -p "${LINTBALL_DIR}/lib/installers" && \
    mkdir -p "${LINTBALL_DIR}/tools/bin"

# Basic scripts for installing/configuring asdf
COPY configs/asdfrc "${LINTBALL_DIR}/configs/asdfrc"
COPY lib/env.bash "${LINTBALL_DIR}/lib/env.bash"
COPY lib/install.bash "${LINTBALL_DIR}/lib/install.bash"
COPY lib/installers/asdf.bash "${LINTBALL_DIR}/lib/installers/asdf.bash"

RUN bash -c "set -euxo pipefail && source ${LINTBALL_DIR}/lib/env.bash && source ${LINTBALL_DIR}/lib/install.bash && configure_asdf"
## </base image> ##############################################################

## <tool images> ##############################################################
FROM --platform=$TARGETPLATFORM lintball-base as lintball-install-nimpretty
COPY lib/installers/nim.bash "${LINTBALL_DIR}/lib/installers/nim.bash"
RUN bash -c "set -euxo pipefail && source ${LINTBALL_DIR}/lib/env.bash && source ${LINTBALL_DIR}/lib/install.bash && install_nimpretty"

FROM --platform=$TARGETPLATFORM lintball-base as lintball-install-shellcheck
COPY lib/installers/shellcheck.bash "${LINTBALL_DIR}/lib/installers/shellcheck.bash"
RUN bash -c "set -euxo pipefail && source ${LINTBALL_DIR}/lib/env.bash && source ${LINTBALL_DIR}/lib/install.bash && install_shellcheck"

FROM --platform=$TARGETPLATFORM lintball-base as lintball-install-shfmt
COPY lib/installers/shfmt.bash "${LINTBALL_DIR}/lib/installers/shfmt.bash"
RUN bash -c "set -euxo pipefail && source ${LINTBALL_DIR}/lib/env.bash && source ${LINTBALL_DIR}/lib/install.bash && install_shfmt"

FROM --platform=$TARGETPLATFORM lintball-base as lintball-install-python
COPY lib/installers/python.bash "${LINTBALL_DIR}/lib/installers/python.bash"
COPY tools/pip-requirements.txt "${LINTBALL_DIR}/tools/pip-requirements.txt"
RUN bash -c "set -euxo pipefail && source ${LINTBALL_DIR}/lib/env.bash && source ${LINTBALL_DIR}/lib/install.bash && install_python"

FROM --platform=$TARGETPLATFORM lintball-base as lintball-install-nodejs
COPY --from=lintball-install-python "${LINTBALL_DIR}/tools/asdf/installs/python" "${LINTBALL_DIR}/tools/asdf/installs/python"
COPY --from=lintball-install-python "${LINTBALL_DIR}/tools/asdf/plugins/python" "${LINTBALL_DIR}/tools/asdf/plugins/python"
COPY lib/installers/nodejs.bash "${LINTBALL_DIR}/lib/installers/nodejs.bash"
COPY tools/package.json "${LINTBALL_DIR}/tools/package.json"
COPY tools/package-lock.json "${LINTBALL_DIR}/tools/package-lock.json"
RUN bash -c "set -euxo pipefail && source ${LINTBALL_DIR}/lib/env.bash && source ${LINTBALL_DIR}/lib/install.bash && install_nodejs"

FROM --platform=$TARGETPLATFORM debian:bookworm-slim as lintball-composite
ENV LINTBALL_DIR=/lintball
COPY --from=lintball-base "${LINTBALL_DIR}/tools/asdf" "${LINTBALL_DIR}/tools/asdf"
COPY --from=lintball-install-nimpretty "${LINTBALL_DIR}/tools/bin/nimpretty" "${LINTBALL_DIR}/tools/bin/nimpretty"
COPY --from=lintball-install-nodejs "${LINTBALL_DIR}/tools/asdf/installs/nodejs" "${LINTBALL_DIR}/tools/asdf/installs/nodejs"
COPY --from=lintball-install-nodejs "${LINTBALL_DIR}/tools/asdf/plugins/nodejs" "${LINTBALL_DIR}/tools/asdf/plugins/nodejs"
COPY --from=lintball-install-nodejs "${LINTBALL_DIR}/tools/node_modules" "${LINTBALL_DIR}/tools/node_modules"
COPY --from=lintball-install-python "${LINTBALL_DIR}/tools/asdf/installs/python" "${LINTBALL_DIR}/tools/asdf/installs/python"
COPY --from=lintball-install-python "${LINTBALL_DIR}/tools/asdf/plugins/python" "${LINTBALL_DIR}/tools/asdf/plugins/python"
COPY --from=lintball-install-python "${LINTBALL_DIR}/tools/pip-requirements.txt" "${LINTBALL_DIR}/tools/pip-requirements.txt"
COPY --from=lintball-install-shellcheck "${LINTBALL_DIR}/tools/asdf/installs/shellcheck" "${LINTBALL_DIR}/tools/asdf/installs/shellcheck"
COPY --from=lintball-install-shellcheck "${LINTBALL_DIR}/tools/asdf/plugins/shellcheck" "${LINTBALL_DIR}/tools/asdf/plugins/shellcheck"
COPY --from=lintball-install-shfmt "${LINTBALL_DIR}/tools/asdf/installs/shfmt" "${LINTBALL_DIR}/tools/asdf/installs/shfmt"
COPY --from=lintball-install-shfmt "${LINTBALL_DIR}/tools/asdf/plugins/shfmt" "${LINTBALL_DIR}/tools/asdf/plugins/shfmt"
COPY .gitignore "${LINTBALL_DIR}/.gitignore"
COPY .lintballrc.json "${LINTBALL_DIR}/.lintballrc.json"
COPY bin "${LINTBALL_DIR}/bin"
COPY configs "${LINTBALL_DIR}/configs"
COPY githooks "${LINTBALL_DIR}/githooks"
COPY lib "${LINTBALL_DIR}/lib"
COPY LICENSE "${LINTBALL_DIR}/LICENSE"
COPY package-lock.json "${LINTBALL_DIR}/package-lock.json"
COPY package.json "${LINTBALL_DIR}/package.json"
COPY README.md "${LINTBALL_DIR}/README.md"
COPY scripts "${LINTBALL_DIR}/scripts"
COPY test "${LINTBALL_DIR}/test"
COPY tools/.eslintrc.cjs "${LINTBALL_DIR}/tools/.eslintrc.cjs"
COPY tools/.prettierrc.json "${LINTBALL_DIR}/tools/.prettierrc.json"
COPY tools/Gemfile "${LINTBALL_DIR}/tools/Gemfile"
COPY tools/Gemfile.lock "${LINTBALL_DIR}/tools/Gemfile.lock"
COPY tools/package-lock.json "${LINTBALL_DIR}/tools/package-lock.json"
COPY tools/package.json "${LINTBALL_DIR}/tools/package.json"
RUN bash -c "set -euxo pipefail && source ${LINTBALL_DIR}/lib/env.bash && source ${LINTBALL_DIR}/lib/install.bash && configure_asdf && asdf reshim"
## </tool images> #############################################################

## <latest image> #############################################################
# Output image does not inherit from lintball-base because we don't need all
# of the installed debian packages.
FROM --platform=$TARGETPLATFORM debian:bookworm-slim as lintball-latest
ENV LINTBALL_DIR=/lintball
RUN echo 'source "${LINTBALL_DIR}/lib/env.bash"' >> ~/.bashrc
COPY --from=lintball-composite "${LINTBALL_DIR}" "${LINTBALL_DIR}"

# Install:
# - jq for parsing lintballrc.json
# - git for pre-commit hook
# - procps for ps command, used in lintball
RUN apt update && apt install -y parallel jq git procps && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /tmp/* && \
    rm -rf /var/tmp/*

ENTRYPOINT ["/lintball/scripts/docker-entrypoint.bash"]
WORKDIR "/workspace"
CMD ["lintball", "check", "."]
## </latest image> ############################################################

## <test image> ###############################################################
## The test image contains ruby and uncrustify
FROM --platform=$TARGETPLATFORM lintball-base as lintball-install-ruby
ENV LINTBALL_DIR=/lintball
COPY lib/installers/ruby.bash "${LINTBALL_DIR}/lib/installers/ruby.bash"
COPY tools/Gemfile "${LINTBALL_DIR}/tools/Gemfile"
COPY tools/Gemfile.lock "${LINTBALL_DIR}/tools/Gemfile.lock"
RUN bash -c "set -euxo pipefail && source ${LINTBALL_DIR}/lib/env.bash && source ${LINTBALL_DIR}/lib/install.bash && install_ruby"

FROM --platform=$TARGETPLATFORM lintball-base as lintball-install-rust
ENV LINTBALL_DIR=/lintball
COPY lib/installers/rust.bash "${LINTBALL_DIR}/lib/installers/rust.bash"
RUN bash -c "set -euxo pipefail && source ${LINTBALL_DIR}/lib/env.bash && source ${LINTBALL_DIR}/lib/install.bash && install_clippy && install_stylua"

FROM --platform=$TARGETPLATFORM lintball-install-python as lintball-install-uncrustify
ENV LINTBALL_DIR=/lintball
COPY lib/installers/uncrustify.bash "${LINTBALL_DIR}/lib/installers/uncrustify.bash"
RUN bash -c "set -euxo pipefail && source ${LINTBALL_DIR}/lib/env.bash && source ${LINTBALL_DIR}/lib/install.bash && install_uncrustify"

FROM --platform=$TARGETPLATFORM lintball-latest as lintball-test
ENV LINTBALL_DIR=/lintball
COPY --from=lintball-install-ruby "${LINTBALL_DIR}/tools/.bundle" "${LINTBALL_DIR}/tools/asdf/.bundle"
COPY --from=lintball-install-ruby "${LINTBALL_DIR}/tools/asdf/installs/ruby" "${LINTBALL_DIR}/tools/asdf/installs/ruby"
COPY --from=lintball-install-ruby "${LINTBALL_DIR}/tools/asdf/plugins/ruby" "${LINTBALL_DIR}/tools/asdf/plugins/ruby"
COPY --from=lintball-install-rust "${LINTBALL_DIR}/tools/asdf/installs/rust" "${LINTBALL_DIR}/tools/asdf/installs/rust"
COPY --from=lintball-install-rust "${LINTBALL_DIR}/tools/asdf/plugins/rust" "${LINTBALL_DIR}/tools/asdf/plugins/rust"
COPY --from=lintball-install-uncrustify "${LINTBALL_DIR}/tools/bin/uncrustify" "${LINTBALL_DIR}/tools/bin/uncrustify"

# Install:
# - jq for parsing lintballrc.json
# - git for pre-commit hook
# - libyaml for ruby
# - procps for ps command, used in lintball
RUN apt update && apt install -y parallel jq git libyaml procps && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /tmp/* && \
    rm -rf /var/tmp/*

RUN bash -c "source ${LINTBALL_DIR}/lib/env.bash && \
    cd ${LINTBALL_DIR}/tools && \
    asdf reshim && \
    npm ci --include=dev && \
    npm cache clean --force && \
    asdf reshim && \
    rm -rf /tmp/* && \
    rm -rf /var/tmp/*"

WORKDIR "${LINTBALL_DIR}/tools"
## </test image> ##############################################################
