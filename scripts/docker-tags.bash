declare -a docker_tags=()
declare -a cache_from_args=()
declare -a tag_args=()

# regex to parse semver 2.0.0, with pre-release and build number
git_branch_or_tag_name=${GITHUB_REF_NAME:-$(git rev-parse --abbrev-ref HEAD)}

if [[ -z $git_branch_or_tag_name ]]; then
  git_branch_or_tag_name=$(git rev-parse --abbrev-ref HEAD)
fi

cache_from_args+=(--cache-from=elijahru/lintball:git--devel --cache-from=elijahru/lintball:latest)

if [[ ${git_branch_or_tag_name:-} =~ ^v?(([0-9]+)\.([0-9]+)\.([0-9]+)(-([a-zA-Z0-9-]+))?(\+([a-zA-Z0-9\.-]+))?)$ ]]; then
  major="${BASH_REMATCH[2]}"
  minor="${BASH_REMATCH[3]}"
  patch="${BASH_REMATCH[4]}"

  # Cache from v1, v1.2, v1.2.3
  cache_from_args+=(--cache-from="v${major}" --cache-from="v${major}.${minor}" --cache-from="v${major}.${minor}.${patch}")

  if [ -z "${BASH_REMATCH[5]}" ]; then
    # Release: push to latest, v1, v1.2, v1.2.3
    docker_tags+=("latest" "v${major}" "v${major}.${minor}" "v${major}.${minor}.${patch}")
  else
    main_tag="git--${git_branch_or_tag_name//[^a-zA-Z0-9]/-}"
    # Pre-release: push to git--1.2.3-beta
    docker_tags+=("$main_tag")
    # Cache from git--1.2.3-beta
    cache_from_args+=(--cache-from="$main_tag")
  fi
else
  # Not a semantic version, just use the branch or tag
  main_tag="git--${git_branch_or_tag_name//[^a-zA-Z0-9]/-}"
  docker_tags+=("$main_tag")

  # Cache from git--foo
  if [[ $main_tag != "git--devel" ]]; then
    # git--devel is always included so don't repeat it
    cache_from_args+=(--cache-from="$main_tag")
  fi

  if [[ -n $(command -v jq) ]]; then
    lintball_version=$(jq -r .version "package.json")
  elif [[ -n $(command -v npm) ]]; then
    lintball_version=$(npm pkg get version --parseable | tr -d '"')
  else
    echo >&2
    echo "Could not find jq or npm. Please install one of them." >&2
    exit 1
  fi

  major=$(echo "${lintball_version}" | awk -F '.' '{print $1}')
  minor=$(echo "${lintball_version}" | awk -F '.' '{print $2}')
  patch=$(echo "${lintball_version}" | awk -F '.' '{print $3}')

  # Cache from v1, v1.2, v1.2.3
  cache_from_args+=(--cache-from="v${major}" --cache-from="v${major}.${minor}" --cache-from="v${major}.${minor}.${patch}")
fi

for tag in "${docker_tags[@]}"; do
  tag_args+=(--tag="elijahru/lintball:$tag")
done
