#!/bin/bash

# This script is used to run lintball via GitHub Actions.
# It is used internally by the elijahr/lintball action and runs lintball
# in a Docker container.

set -euxo pipefail

IFS= read -r check_all_files < <(printenv 'INPUT_CHECK_ALL_FILES')
IFS= read -r committish < <(printenv 'INPUT_COMMITTISH')
IFS= read -r default_branch < <(printenv 'INPUT_DEFAULT_BRANCH')
IFS= read -r workspace < <(printenv 'INPUT_WORKSPACE')

if [[ -n $(command -v jq) ]]; then
  IFS= read -r lintball_version < <(jq -r .version "${GITHUB_ACTION_PATH}/package.json")
elif [[ -n $(command -v npm) ]]; then
  # shellcheck disable=SC2016
  lintball_version=$(
    cd "${GITHUB_ACTION_PATH}"
    npm -s run env echo '$npm_package_version'
  )
else
  echo >&2
  echo "Could not find jq or npm. Please install one of them." >&2
  exit 1
fi
IFS= read -r lintball_major_version < <(echo "${lintball_version}" | awk -F '.' '{print $1}')

case "${check_all_files}" in
  true | false) ;;

  *)
    echo >&2
    echo "Invalid value for check-all-files: ${check_all_files}" >&2
    echo "Must be true or false." >&2
    exit 1
    ;;
esac

declare -a lintball_check_args=()
if [[ ${check_all_files} == "true" ]]; then
  lintball_check_args+=(".")
else
  if [[ ${committish} == "<auto>" ]]; then
    # Use the GitHub API to get the default branch if it's not specified.
    # If this gets rate-limited, you can set the default branch manually or
    # provide the GITHUB_TOKEN environment variable.
    if [[ ${default_branch} == "<auto>" ]]; then
      declare headers=()
      if [[ -n ${GITHUB_TOKEN:-} ]]; then
        headers+=(-H "Authorization: token ${GITHUB_TOKEN}")
      fi
      default_branch=$(curl -sSL "${headers[@]}" "${GITHUB_API_URL}/repos/${GITHUB_REPOSITORY}" |
        grep default_branch |
        sed 's/^.*"default_branch": "\([^"]\{1,\}\)".*$/\1/')
    fi

    if [[ -z ${default_branch} ]]; then
      echo >&2
      echo "Unable to determine default branch." >&2
      echo >&2
      echo "Please set the default branch manually." >&2
      echo "For instance, if your default branch is master:" >&2
      echo "  uses: elijahr/lintball@v${lintball_major_version}" >&2
      echo "  with:" >&2
      echo "    default-branch: master" >&2
      echo >&2
      echo "Or, provide the GITHUB_TOKEN environment variable:" >&2
      echo "  uses: elijahr/lintball@v${lintball_major_version}" >&2
      echo "  with:" >&2
      echo "    env:" >&2
      # shellcheck disable=SC2016
      echo '      GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}' >&2
      echo >&2
      exit 1
    fi

    if [[ ${GITHUB_REF} == "refs/heads/${default_branch}" ]]; then
      # A push to the default branch.
      # Check files which were changed in the most recent commit.
      committish="HEAD~1"
    elif [[ -n ${GITHUB_BASE_REF:-} ]]; then
      # A pull request.
      # Check files which have changed between the merge base and the
      # current commit.
      IFS= read -r committish < <(git merge-base -a "refs/remotes/origin/${GITHUB_BASE_REF}" "${GITHUB_SHA}")
    else
      # A push to a non-default, non-PR branch.
      # Check files which have changed between default branch and the current
      # commit.
      IFS= read -r committish < <(git merge-base -a "refs/remotes/origin/${default_branch}" "${GITHUB_SHA}")
    fi
  fi
  if [[ -z ${committish} ]]; then
    echo >&2
    echo "Unable to determine committish." >&2
    echo >&2
    echo "Committish may be set manually." >&2
    echo "For instance, if you want to check files changed in the most recent commit:" >&2
    echo "  uses: elijahr/lintball@v${lintball_major_version}" >&2
    echo "  with:" >&2
    echo "    committish: HEAD~1" >&2
    echo >&2
    exit 1
  fi
  lintball_check_args+=("--since" "${committish}")
fi

LINTBALL_DOCKERHUB_IMAGE_TAG="${lintball_version}"
export LINTBALL_DOCKERHUB_IMAGE_TAG
LINTBALL_WORKSPACE="${workspace}"
export LINTBALL_WORKSPACE

if ! docker-compose run -f "${GITHUB_ACTION_PATH}/docker-compose.yml" lintball \
  lintball check "${lintball_check_args[@]}"; then
  status=$?
  echo >&2
  echo "The above issues were found by lintball." >&2
  echo "To detect and auto-fix issues before pushing, install lintball's git hooks." >&2
  echo "See https://github.com/elijahr/lintball" >&2
  echo >&2
  exit $status
fi
