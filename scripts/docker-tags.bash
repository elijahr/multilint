declare -a docker_tags=()

# regex to parse semver 2.0.0, with pre-release and build number
git_branch_or_tag_name=${GITHUB_REF_NAME:-$(git rev-parse --abbrev-ref HEAD)}

if [[ -z $git_branch_or_tag_name ]]; then
  git_branch_or_tag_name=$(git rev-parse --abbrev-ref HEAD)
fi

if [[ ${git_branch_or_tag_name:-} =~ ^v?(([0-9]+)\.([0-9]+)\.([0-9]+)(-([a-zA-Z0-9-]+))?(\+([a-zA-Z0-9\.-]+))?)$ ]]; then
  major="${BASH_REMATCH[2]}"
  minor="${BASH_REMATCH[3]}"
  patch="${BASH_REMATCH[4]}"

  if [ -z "${BASH_REMATCH[5]}" ]; then
    # not a pre-release, tag latest
    main_tag="latest"
    docker_tags+=("latest" "v${major}" "v${major}.${minor}" "v${major}.${minor}.${patch}")
  else
    # pre-release, just use the tag
    main_tag="git--${git_branch_or_tag_name//[^a-zA-Z0-9]/-}"
    docker_tags+=("$main_tag")
  fi
else
  # not a semantic version, just use the branch or tag
  main_tag="git--${git_branch_or_tag_name//[^a-zA-Z0-9]/-}"
  docker_tags+=("$main_tag")
fi

if [[ -n $(command -v jq) ]]; then
  IFS= read -r lintball_version < <(jq -r .version "package.json")
elif [[ -n $(command -v npm) ]]; then
  # shellcheck disable=SC2016
  lintball_version=$(npm -s run env echo '$npm_package_version')
else
  echo >&2
  echo "Could not find jq or npm. Please install one of them." >&2
  exit 1
fi

IFS= read -r lintball_major_version < <(echo "${lintball_version}" | awk -F '.' '{print $1}')
for tag in "${docker_tags[@]}"; do
  if [[ $tag == "v${lintball_major_version}" ]]; then
    found=true
    break
  fi
done

if [[ -z ${found:-} ]]; then
  docker_tags+=("v${lintball_major_version}")
fi
