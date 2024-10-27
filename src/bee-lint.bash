########################################
# Lint plugin specification file
# Arguments:
#   path
########################################

if (( ! $# )); then
  bee::source "bee-help"
  exit 1
fi

declare -ig lint_error=0

bee::lint::assert_equal() {
  local key="$1" actual="$2" expected="$3"
  if [[ "${actual}" == "${expected}" ]]; then
    printf '%-24b%b\n' "${BEE_COLOR_SUCCESS}${key}" "${BEE_CHECK_SUCCESS} ${actual}${BEE_COLOR_RESET}"
  else
    printf '%-24b%b\n' "${BEE_COLOR_FAIL}${key}" "${BEE_CHECK_FAIL} ${actual} (must be ${expected})${BEE_COLOR_RESET}"
    lint_error=1
  fi
}

bee::lint::assert_exist() {
  local key="$1" actual="$2"
  if [[ "${actual}" != "null" ]]; then
    printf '%-24b%b\n' "${BEE_COLOR_SUCCESS}${key}" "${BEE_CHECK_SUCCESS} ${actual}${BEE_COLOR_RESET}"
  else
    printf '%-24b%b\n' "${BEE_COLOR_FAIL}${key}" "${BEE_CHECK_FAIL} ${actual} (required)${BEE_COLOR_RESET}"
    lint_error=1
  fi
}

bee::lint::optional() {
  local key="$1" actual="$2"
  if [[ "${actual}" != "null" ]]
  then printf '%-24b%b\n' "${BEE_COLOR_SUCCESS}${key}" "${BEE_CHECK_SUCCESS} ${actual}${BEE_COLOR_RESET}"
  else printf '%-24b%b\n' "${BEE_COLOR_WARN}${key}" "${actual}${BEE_COLOR_RESET}"
  fi
}

spec_path="$1"

key="name"
plugin_name="$(jq -rc --arg key "${key}" '.[$key]' "${spec_path}")"
expected="$(basename "$(dirname "$(dirname "${spec_path}")")")"
bee::lint::assert_equal "${key}" "${plugin_name}" "${expected}"

key="version"
actual="$(jq -rc --arg key "${key}" '.[$key]' "${spec_path}")"
expected="$(basename "$(dirname "${spec_path}")")"
bee::lint::assert_equal "${key}" "${actual}" "${expected}"

key="license"
actual="$(jq -rc --arg key "${key}" '.[$key]' "${spec_path}")"
bee::lint::assert_exist "${key}" "${actual}"

key="homepage"
actual="$(jq -rc --arg key "${key}" '.[$key]' "${spec_path}")"
bee::lint::assert_exist "${key}" "${actual}"

key="authors"
actual="$(jq -rc --arg key "${key}" '.[$key]' "${spec_path}")"
bee::lint::assert_exist "${key}" "${actual}"

key="info"
actual="$(jq -rc --arg key "${key}" '.[$key]' "${spec_path}")"
bee::lint::assert_exist "${key}" "${actual}"

key="git"
git_url="$(jq -rc --arg key "${key}" '.[$key]' "${spec_path}")"
bee::lint::assert_exist "${key}" "${git_url}"

key="tag"
git_tag="$(jq -rc --arg key "${key}" '.[$key]' "${spec_path}")"
bee::lint::assert_exist "${key}" "${git_tag}"

key="sha256"
sha256_hash="$(jq -rc --arg key "${key}" '.[$key]' "${spec_path}")"
bee::lint::assert_exist "${key}" "${sha256_hash}"

key="dependencies"
plugin_deps=("$(jq -rc --arg key "${key}" '.[$key][]? // null' "${spec_path}")")
bee::lint::optional "${key}" "${plugin_deps[@]}"

cache_path="$(bee::to_cache_path "${git_url}")"
if [[ -n "${cache_path}" ]]; then
  cache_path="${BEE_CACHE_PATH}/lint/${cache_path}"
  if [[ -d "${cache_path}" ]]; then
    pushd "${cache_path}" >/dev/null || exit 1
      bee::source "bee-job" "git fetch" git fetch
    popd >/dev/null || exit 1
  else
    bee::source "bee-job" "git clone" git clone "${git_url}" "${cache_path}"
  fi
fi

if [[ -n "${cache_path}" && -d "${cache_path}" ]]; then
  pushd "${cache_path}" >/dev/null || exit 1
    bee::source "bee-job" "git checkout tag" git checkout -q "${git_tag}"

    key="version file"
    version_file="version.txt"
    if [[ -f "${version_file}" ]]; then
      actual="$(cat "${version_file}")"
      expected="$(basename "$(dirname "${spec_path}")")"
      bee::lint::assert_equal "${key}" "${actual}" "${expected}"
    else
      version_file="null"
      bee::lint::assert_exist "${key}" "${version_file}"
    fi

    key="license file"
    license_file="LICENSE.txt"
    [[ -f "${license_file}" ]] || license_file="null"
    bee::lint::assert_exist "${key}" "${license_file}"

    key="sha256"
    hash="$(bee::source "bee-hash" "${PWD}")"
    bee::lint::assert_equal "${key}" "${sha256_hash}" "${hash}"

    key="plugin file"
    plugin_file="${plugin_name}.bash"
    [[ -f "${plugin_file}" ]] || plugin_file="null"
    bee::lint::assert_exist "${key}" "${plugin_file}"

    key="dependencies"
    if [[ -f plugin.json ]]
    then deps="$(jq -r '.dependencies[]? // null' plugin.json)"
    else deps="null"
    fi
    bee::lint::assert_equal "${key}" \
      "$(echo "${plugin_deps[@]}" | tr '\n' ' ')" \
      "$(echo "${deps}" | tr '\n' ' ')"
  popd >/dev/null || exit 1
fi

(( ! lint_error )) || exit 1
