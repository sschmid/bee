# bee::help
# hub ls [-a | --all] [<urls>] : list hubs and their plugins (--all versions)
# hub plugins [<urls>] : list plugins
# hub pull [-f | --force] [<urls>] : update hubs (--force ignore pull cooldown)
# hub info <plugin> : print plugin spec
# hub install [-f | --force] [<plugins>] : install plugins (--force ignore sha256 mismatch)
# hub hash <path> : generate plugin hash
# hub lint <spec> : validate plugin spec
# bee::help

: "${BEE_HUB_PULL_COOLDOWN:=900}"

BEE_HUBS_CACHE_PATH="${BEE_CACHES_PATH}/hubs"
BEE_LINT_CACHE_PATH="${BEE_CACHES_PATH}/lint"

bee::hub::comp() {
  local cmd="${1:-}"
  if ((!$# || $# == 1 && COMP_PARTIAL)); then
    local comps=(ls plugins pull info install hash lint)
    local IFS=' '
    compgen -W "${comps[*]}" -- "${cmd}"
  else
    case "${cmd}" in
      ls) shift; bee::hub::ls::comp "$@" ;;
      plugins) echo "${BEE_HUBS[*]}" ;;
      pull) shift; bee::hub::pull::comp "$@" ;;
      info) shift; bee::hub::info::comp "$@" ;;
      install) shift; bee::hub::install::comp "$@" ;;
    esac
  fi
}

bee::hub::install::comp() {
  local plugins
  plugins="$(bee::hub::plugins)"
  if ((!$# || $# == 1 && COMP_PARTIAL)); then
    local cmd="${1:-}"
    local comps=("-f --force" "${plugins}")
    local IFS=' '
    compgen -W "${comps[*]}" -- "${cmd}"
  else
    echo "${plugins}"
  fi
}

bee::hub::ls::comp() {
  if ((!$# || $# == 1 && COMP_PARTIAL)); then
    local cmd="${1:-}"
    local comps=("-a --all ${BEE_HUBS[*]}")
    local IFS=' '
    compgen -W "${comps[*]}" -- "${cmd}"
  else
    echo "${BEE_HUBS[*]}"
  fi
}

bee::hub::pull::comp() {
  if ((!$# || $# == 1 && COMP_PARTIAL)); then
    local cmd="${1:-}"
    local comps=("-f --force ${BEE_HUBS[*]}")
    local IFS=' '
    compgen -W "${comps[*]}" -- "${cmd}"
  else
    echo "${BEE_HUBS[*]}"
  fi
}

bee::hub::info::comp() {
  local plugins
  plugins="$(bee::hub::plugins)"
  if ((!$# || $# == 1 && COMP_PARTIAL)); then
    echo "${plugins}"
  fi
}

bee::hub() {
  if (($#)); then
    case "$1" in
      ls) shift; bee::hub::ls "$@" ;;
      plugins) shift; bee::hub::plugins "$@" ;;
      pull) shift; bee::hub::pull "$@" ;;
      info) shift; bee::hub::info "$@" ;;
      install) shift; echo "Installing"; bee::hub::install "$@" ;;
      hash) shift; bee::hub::hash "$@" ;;
      lint) shift; bee::hub::lint "$@" ;;
      *) bee::usage ;;
    esac
  else
    bee::usage
  fi
}

bee::hub::ls() {
  local -i show_all=0
  while (($#)); do case "$1" in
    -a | --all) show_all=1; shift ;;
    --) shift; break ;; *) break ;;
  esac done

  local cache_path plugin_name plugin_version indent bullet
  local -a plugins versions
  local -i i j n m
  for url in "${@:-"${BEE_HUBS[@]}"}"; do
    cache_path="${BEE_HUBS_CACHE_PATH}/$(bee::hub::to_cache_path "${url}")"
    if [[ -n "$cache_path" ]]; then
      echo "${url}"
      if [[ -d "${cache_path}" ]]; then
        mapfile -t plugins < <(ls "${cache_path}")
        n=${#plugins[@]}
        for ((i = 0; i < n; i++)); do
          plugin_name="${plugins[i]}"
          ((i == n - 1)) && bullet="└── " || bullet="├── "
          echo "${bullet}${plugin_name}"

          if ((show_all)); then
            mapfile -t versions < <(find "${cache_path}/${plugin_name}" -mindepth 1 -maxdepth 1 -type d | sort -V)
            m=${#versions[@]}
            for ((j = 0; j < m; j++)); do
              plugin_version="$(basename "${versions[j]}")"
              ((i == n - 1)) && indent="    " || indent="│    "
              ((j == m - 1)) && bullet="└── " || bullet="├── "
              echo "${indent}${bullet}${plugin_version}"
            done
          fi
        done
        echo
      fi
    fi
  done
}

bee::hub::plugins() {
  local cache_path
  for url in "${@:-"${BEE_HUBS[@]}"}"; do
    cache_path="${BEE_HUBS_CACHE_PATH}/$(bee::hub::to_cache_path "${url}")"
    [[ -n "$cache_path" && -d "${cache_path}" ]] && ls "${cache_path}"
  done | sort -u
}

bee::hub::pull() {
  local -i force=0 pull=0
  while (($#)); do case "$1" in
    -f | --force) force=1; shift ;;
    --) shift; break ;; *) break ;;
  esac done

  mkdir -p "${BEE_HUBS_CACHE_PATH}"
  local cache_file="${BEE_HUBS_CACHE_PATH}/.ts"

  if ((force)); then
    pull=1
  else
    local -i now ts delta
    [[ ! -f "${cache_file}" ]] && echo "0" > "${cache_file}"
    now=$(date +%s)
    ts="$(cat "${cache_file}")"
    delta=$((now - ts))
    ((delta > BEE_HUB_PULL_COOLDOWN)) && pull=1
  fi

  if ((pull)); then
    local cache_path
    for url in "${@:-"${BEE_HUBS[@]}"}"; do
      cache_path="${BEE_HUBS_CACHE_PATH}/$(bee::hub::to_cache_path "${url}")"
      if [[ -n "$cache_path" ]]; then
        if [[ -d "${cache_path}" ]]; then
          pushd "${cache_path}" > /dev/null || exit 1
            git pull
          popd > /dev/null || exit 1
        else
          git clone "${url}" "${cache_path}"
        fi
      fi
    done
    date +%s > "${cache_file}"
  fi
}

bee::hub::info() {
  local plugin="$1" plugin_name plugin_version cache_path spec_path
  local -i found=0
  for url in "${BEE_HUBS[@]}"; do
    cache_path="${BEE_HUBS_CACHE_PATH}/$(bee::hub::to_cache_path "${url}")"
    while read -r plugin_name plugin_version spec_path; do
      found=1
      jq . "${spec_path}" || cat "${spec_path}"
    done < <(bee::resolve "${plugin}" "${cache_path}" "plugin.json")
    ((found)) && break
  done
}

bee::hub::install() {
  local -i force=0
  while (($#)); do case "$1" in
    -f | --force) force=1; shift ;;
    --) shift; break ;; *) break ;;
  esac done
  bee::hub::install_recursively ${force} "" "$@"
}

bee::hub::install_recursively() {
  local -i force="$1";
  local indent="$2";
  shift 2
  local -a plugins=("$@") missing=()
  local plugin plugin_name plugin_version cache_path spec_path bullet
  local -i i n=${#plugins[@]} found=0 already_installed=0
  for ((i = 0; i < n; i++)); do
    found=0
    plugin="${plugins[i]}"
    ((i == n - 1)) && bullet="└── " || bullet="├── "
    for url in "${BEE_HUBS[@]}"; do
      cache_path="${BEE_HUBS_CACHE_PATH}/$(bee::hub::to_cache_path "${url}")"
      while read -r plugin_name plugin_version spec_path; do
        found=1
        local plugin_path="${BEE_CACHES_PATH}/plugins/${plugin_name}/${plugin_version}"
        local git tag sha deps
        while read -r git tag sha deps; do
          if [[ -d "${plugin_path}" ]]; then
            already_installed=1
          else
            already_installed=0
            git -c advice.detachedHead=false clone -q --depth 1 --branch "${tag}" "${git}" "${plugin_path}"
          fi
          bee::hub::hash "${plugin_path}" > /dev/null
          if [[ "${BEE_HUB_HASH_RESULT}" != "${sha}" ]]; then
            if ((force)); then
              bee::log_warn "${plugin_name}:${plugin_version} sha256 mismatch!" \
                "Plugin was tampered with or version has been modified. Authenticity is not guaranteed." \
                "Consider deleting ${plugin_path} and run 'bee hub install ${plugin_name}:${plugin_version}'."
              echo -e "${indent}${bullet}${BEE_COLOR_WARN}${BEE_CHECK_SUCCESS}︎ ${plugin_name}:${plugin_version} (${url})${BEE_COLOR_RESET}"
            else
              bee::log_error "${plugin_name}:${plugin_version} sha256 mismatch!" "Deleting ${plugin_path}" \
                "Use 'bee hub info ${plugin_name}:${plugin_version}' to inspect the plugin definition." \
                "Use 'bee hub install -f ${plugin_name}:${plugin_version}' to install anyway and proceed at your own risk."
              rm -rf "${plugin_path}"
              echo -e "${indent}${bullet}${BEE_COLOR_FAIL}${BEE_CHECK_FAIL} ${plugin_name}:${plugin_version}${BEE_COLOR_RESET}"
            fi
          else
            if ((already_installed)); then
              echo -e "${indent}${bullet}︎${plugin_name}:${plugin_version} (${url})"
            else
              echo -e "${indent}${bullet}${BEE_COLOR_SUCCESS}${BEE_CHECK_SUCCESS}︎ ${plugin_name}:${plugin_version} (${url})${BEE_COLOR_RESET}"
            fi
          fi
          # shellcheck disable=SC2086
          if [[ -n "${deps}" ]]; then
            if ((i == n - 1)); then
              bee::hub::install_recursively ${force} "${indent}    " ${deps}
            else
              bee::hub::install_recursively ${force} "${indent}│   " ${deps}
            fi
          fi
        done < <(jq -r '[.git, .tag, .sha256, .dependencies[]?] | @tsv' "${spec_path}")
      done < <(bee::resolve "${plugin}" "${cache_path}" "plugin.json")
      ((found)) && break
    done
    if ((!found)); then
      missing+=("${plugin}")
      echo -e "${indent}${bullet}${BEE_COLOR_FAIL}${BEE_CHECK_FAIL} ${plugin}${BEE_COLOR_RESET}"
    fi
  done
  if ((${#missing[@]})); then
    for m in "${missing[@]}"; do
      bee::log_error "Couldn't install plugin: ${m}"
    done
    exit 1
  fi
}

BEE_HUB_HASH_RESULT=""
bee::hub::hash() {
  [[ ! -v BEE_HUB_HASH_EXCLUDE ]] && BEE_HUB_HASH_EXCLUDE=(".git" ".DS_Store")
  local path="$1" file_hash all
  local -a hashes=()
  echo "$path"
  pushd "${path}" > /dev/null || exit 1
    local file
    while read -r file; do
      file_hash="$(os_sha256sum "${file}")"
      echo "${file_hash}"
      hashes+=("${file_hash// */}")
    done < <(find . -type f | grep -vFf <(echo "${BEE_HUB_HASH_EXCLUDE[*]}"))
  popd > /dev/null || exit 1
  all="$(echo "${hashes[*]}" | sort | os_sha256sum)"
  echo "${all}"
  BEE_HUB_HASH_RESULT="${all// */}"
}

bee::hub::lint() {
  local spec_path="$1" key actual expected cache_path plugin_name git_url git_tag sha256_hash
  local -a plugin_deps
  bee::load_module job

  key="name"
  plugin_name="$(jq -rc --arg key "${key}" '.[$key]' "${spec_path}")"
  expected="$(basename "$(dirname "$(dirname "${spec_path}")")")"
  bee::hub::lint::assert_equal "${key}" "${plugin_name}" "${expected}"

  key="version"
  actual="$(jq -rc --arg key "${key}" '.[$key]' "${spec_path}")"
  expected="$(basename "$(dirname "${spec_path}")")"
  bee::hub::lint::assert_equal "${key}" "${actual}" "${expected}"

  key="license"
  actual="$(jq -rc --arg key "${key}" '.[$key]' "${spec_path}")"
  bee::hub::lint::assert_exist "${key}" "${actual}"

  key="homepage"
  actual="$(jq -rc --arg key "${key}" '.[$key]' "${spec_path}")"
  bee::hub::lint::assert_exist "${key}" "${actual}"

  key="authors"
  actual="$(jq -rc --arg key "${key}" '.[$key]' "${spec_path}")"
  bee::hub::lint::assert_exist "${key}" "${actual}"

  key="info"
  actual="$(jq -rc --arg key "${key}" '.[$key]' "${spec_path}")"
  bee::hub::lint::assert_exist "${key}" "${actual}"

  key="git"
  git_url="$(jq -rc --arg key "${key}" '.[$key]' "${spec_path}")"
  bee::hub::lint::assert_exist "${key}" "${git_url}"

  key="tag"
  git_tag="$(jq -rc --arg key "${key}" '.[$key]' "${spec_path}")"
  bee::hub::lint::assert_exist "${key}" "${git_tag}"

  key="sha256"
  sha256_hash="$(jq -rc --arg key "${key}" '.[$key]' "${spec_path}")"
  bee::hub::lint::assert_exist "${key}" "${sha256_hash}"

  key="dependencies"
  plugin_deps=("$(jq -rc --arg key "${key}" '.[$key][]? // null' "${spec_path}")")
  bee::hub::lint::optional "${key}" "${plugin_deps}"

  cache_path="${BEE_LINT_CACHE_PATH}/$(bee::hub::to_cache_path "${git_url}")"
  if [[ -n "$cache_path" ]]; then
    if [[ -d "${cache_path}" ]]; then
      pushd "${cache_path}" > /dev/null || exit 1
        bee::job "git fetch" git fetch
      popd > /dev/null || exit 1
    else
      bee::job "git clone" git clone "${git_url}" "${cache_path}"
    fi
  fi

  if [[ -n "$cache_path" && -d "${cache_path}" ]]; then
    pushd "${cache_path}" > /dev/null || exit 1
      bee::job "git checkout tag" git checkout -q "${git_tag}"

      key="version file"
      local version_file="version.txt"
      if [[ -f "${version_file}" ]]; then
        actual="$(cat "${version_file}")"
        expected="$(basename "$(dirname "${spec_path}")")"
        bee::hub::lint::assert_equal "${key}" "${actual}" "${expected}"
      else
        version_file="null"
        bee::hub::lint::assert_exist "${key}" "${version_file}"
      fi

      key="license file"
      local license_file="LICENSE.txt"
      [[ ! -f "${license_file}" ]] && license_file="null"
      bee::hub::lint::assert_exist "${key}" "${license_file}"

      key="sha256"
      bee::hub::hash "${PWD}"
      bee::hub::lint::assert_equal "${key}" "${sha256_hash}" "${BEE_HUB_HASH_RESULT}"

      key="plugin file"
      local plugin_file="${plugin_name}.bash"
      if [[ ! -f "${plugin_file}" ]]; then
        plugin_file="null"
        bee::hub::lint::assert_exist "${key}" "${plugin_file}"
      else
        bee::hub::lint::assert_exist "${key}" "${plugin_file}"

        key="dependencies"
        local deps=("$(
          source "${plugin_file}" > /dev/null
          deps="${plugin_name}::deps"
          if [[ $(command -v "${deps}") == "${deps}" ]]; then
            "${deps}"
          else
            echo "null"
          fi
        )")
        bee::hub::lint::assert_equal "${key}" \
          "$(echo "${plugin_deps[@]}" | tr '\n' ' ')" \
          "$(echo "${deps[@]}" | tr '\n' ' ')"
      fi
    popd > /dev/null || exit 1
  fi

  if ((BEE_HUB_LINT_ERROR)); then
    exit 1
  fi
}

declare -ig BEE_HUB_LINT_ERROR=0
bee::hub::lint::assert_equal() {
  local key="$1" actual="$2" expected="$3"
  if [[ "${actual}" == "${expected}" ]]; then
    printf '%-22b%b\n' "${BEE_COLOR_SUCCESS}${key}" "${BEE_CHECK_SUCCESS} ${actual}${BEE_COLOR_RESET}"
  else
    printf '%-22b%b\n' "${BEE_COLOR_FAIL}${key}" "${BEE_CHECK_FAIL} ${actual} (must be ${expected})${BEE_COLOR_RESET}"
    BEE_HUB_LINT_ERROR=1
  fi
}

bee::hub::lint::assert_exist() {
  local key="$1" actual="$2"
  if [[ "${actual}" != "null" ]]; then
    printf '%-22b%b\n' "${BEE_COLOR_SUCCESS}${key}" "${BEE_CHECK_SUCCESS} ${actual}${BEE_COLOR_RESET}"
  else
    printf '%-22b%b\n' "${BEE_COLOR_FAIL}${key}" "${BEE_CHECK_FAIL} ${actual} (required)${BEE_COLOR_RESET}"
    BEE_HUB_LINT_ERROR=1
  fi
}

bee::hub::lint::optional() {
  local key="$1" actual="$2"
  if [[ "${actual}" != "null" ]]
  then printf '%-24b%b\n' "${BEE_COLOR_SUCCESS}${key}" "${BEE_CHECK_SUCCESS} ${actual}${BEE_COLOR_RESET}"
  else printf '%-24b%b\n' "${BEE_COLOR_WARN}${key}" "${actual}${BEE_COLOR_RESET}"
  fi
}

bee::hub::to_cache_path() {
  case "$1" in
    https://*) echo "$(dirname "${1#https://}")/$(basename "$1" .git)" ;;
    git://*) echo "$(dirname "${1#git://}")/$(basename "$1" .git)" ;;
    git@*) local path="${1#git@}"; echo "$(dirname "${path/://}")/$(basename "$1" .git)" ;;
    ssh://*) local path="${1#ssh://}"; echo "$(dirname "${path#git@}")/$(basename "$1" .git)" ;;
    file://*) basename "$1" ;;
    *) bee::log_warn "Unsupported hub url: $1" ;;
  esac
}
