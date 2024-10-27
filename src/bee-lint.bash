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
    printf '%-24b%b\n' "${BEE_COLOR_FAIL}${key}" "${BEE_CHECK_FAIL} ${actual} (must be ${expected})${BEE_COLOR_RESET}" >&2
    lint_error=1
  fi
}

bee::lint::assert_exist() {
  local key="$1" actual="$2"
  if [[ "${actual}" != "null" ]]; then
    printf '%-24b%b\n' "${BEE_COLOR_SUCCESS}${key}" "${BEE_CHECK_SUCCESS} ${actual}${BEE_COLOR_RESET}"
  else
    printf '%-24b%b\n' "${BEE_COLOR_FAIL}${key}" "${BEE_CHECK_FAIL} ${actual} (required)${BEE_COLOR_RESET}" >&2
    lint_error=1
  fi
}

bee::lint::optional() {
  local key="$1" actual="$2"
  if [[ "${actual}" != "null" ]]
  then printf '%-24b%b\n' "${BEE_COLOR_SUCCESS}${key}" "${BEE_CHECK_SUCCESS} ${actual}${BEE_COLOR_RESET}"
  else printf '%-24b%b\n' "${BEE_COLOR_WARN}${key}" "${actual}${BEE_COLOR_RESET}" >&2
  fi
}

bee::lint::assert_key_equals() {
  local key="$1" expected="$2" actual
  actual="$(jq -rc --arg key "${key}" '.[$key]' "${spec_path}")"
  bee::lint::assert_equal "${key}" "${actual}" "${expected}"
}

bee::lint::assert_key_exists() {
  local key="$1" actual
  actual="$(jq -rc --arg key "${key}" '.[$key]' "${spec_path}")"
  bee::lint::assert_exist "${key}" "${actual}"
}

spec_path="$1"

plugin_name="$(jq -rc --arg key "name" '.[$key]' "${spec_path}")"
expected="$(basename "$(dirname "$(dirname "${spec_path}")")")"
bee::lint::assert_equal "name" "${plugin_name}" "${expected}"

expected="$(basename "$(dirname "${spec_path}")")"
bee::lint::assert_key_equals "version" "${expected}"

bee::lint::assert_key_exists "license"
bee::lint::assert_key_exists "homepage"
bee::lint::assert_key_exists "authors"
bee::lint::assert_key_exists "info"

git_url="$(jq -rc --arg key "git" '.[$key]' "${spec_path}")"
bee::lint::assert_exist "git" "${git_url}"

git_tag="$(jq -rc --arg key "tag" '.[$key]' "${spec_path}")"
bee::lint::assert_exist "tag" "${git_tag}"

sha256_hash="$(jq -rc --arg key "sha256" '.[$key]' "${spec_path}")"
bee::lint::assert_exist "sha256" "${sha256_hash}"

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

    license_file="LICENSE.txt"
    [[ -f "${license_file}" ]] || license_file="null"
    bee::lint::assert_exist "license file" "${license_file}"

    hash="$(bee::source "bee-hash" "${PWD}")"
    bee::lint::assert_equal "sha256" "${sha256_hash}" "${hash}"

    plugin_file="${plugin_name}.bash"
    [[ -f "${plugin_file}" ]] || plugin_file="null"
    bee::lint::assert_exist "plugin file" "${plugin_file}"

    if [[ -f plugin.json ]]
    then deps="$(jq -r '.dependencies[]? // null' plugin.json)"
    else deps="null"
    fi
    bee::lint::assert_equal "dependencies" \
      "$(echo -n "${plugin_deps[@]}" | tr '\n' ' ')" \
      "$(echo -n "${deps}" | tr '\n' ' ')"
  popd >/dev/null || exit 1
fi

(( ! lint_error )) || exit 1
