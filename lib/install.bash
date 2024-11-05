set +f
for installer in "${LINTBALL_DIR}/lib/installers/"*.bash; do
  # shellcheck disable=SC1090
  source "${installer}"
done
set -f
