BEE_HUBS_CACHE_PATH="${BEE_CACHES_PATH}/hubs"

bee::hub() {
  if (($# >= 1)); then
    case "$1" in
      pull) shift; bee::hub::pull "$@" ;;
      install) shift; bee::hub::install "$@" ;;
      *) bee::usage ;;
    esac
  else
    bee::usage
  fi
}

bee::hub::pull() {
  mkdir -p "${BEE_HUBS_CACHE_PATH}"
  local cache_path
  for url in "${@:-"${BEE_HUBS[@]}"}"; do
    cache_path="$(bee::hub::to_cache_path "${url}")"
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
}

bee::hub::install() {
  local plugin plugin_name plugin_version cache_path spec_path
  local -i found=0
  for plugin in "$@"; do
    found=0
    plugin_name="${plugin%:*}"
    plugin_version="${plugin##*:}"
    for url in "${BEE_HUBS[@]}"; do
      cache_path="$(bee::hub::to_cache_path "${url}")"
      if [[ "${plugin_name}" == "${plugin_version}" && -d "${cache_path}/${plugin_name}" ]]; then
        plugin_version="$(basename "$(find "${cache_path}/${plugin_name}" -type d -mindepth 1 -maxdepth 1 | sort -rV | head -n 1)")"
      fi
      spec_path="${cache_path}/${plugin_name}/${plugin_version}/spec.json"
      if [[ -f "${spec_path}" ]]; then
        found=1
        local plugin_path="${BEE_CACHES_PATH}/plugins/${plugin_name}/${plugin_version}"
        if [[ -d "${plugin_path}" ]]; then
          echo "${plugin_name}:${plugin_version}"
        else
          local git tag deps
          while read -r git tag deps; do
            git -c advice.detachedHead=false clone -q --depth 1 --branch "${tag}" "${git}" "${plugin_path}"
            echo -e "\033[32m${plugin_name}:${plugin_version} ✔︎\033[0m"
            # shellcheck disable=SC2086
            [[ -n "${deps}" ]] && bee::hub::install ${deps}
          done < <(jq -r '[.git, .tag, .dependencies[]?] | @tsv' "${spec_path}")
        fi
        break
      fi
    done
    if ((!found)); then
      bee::log_error "Couldn't find and install plugin: ${plugin}"
      exit 1
    fi
  done
}

bee::hub::to_cache_path() {
  local url="$1"
  if [[ "${url}" =~ ^https:// ]]; then
    echo "${BEE_HUBS_CACHE_PATH}/$(dirname "${url#https://}")/$(basename "${url}" .git)"
  elif [[ "${url}" =~ ^git:// ]]; then
    echo "${BEE_HUBS_CACHE_PATH}/$(dirname "${url#git://}")/$(basename "${url}" .git)"
  elif [[ "${url}" =~ ^git@ ]]; then
    local path="${url#git@}"
    echo "${BEE_HUBS_CACHE_PATH}/$(dirname "${path/://}")/$(basename "${url}" .git)"
  elif [[ "${url}" =~ ^ssh:// ]]; then
    local path="${url#ssh://}"
    echo "${BEE_HUBS_CACHE_PATH}/$(dirname "${path#git@}")/$(basename "${url}" .git)"
  elif [[ "${url}" =~ ^file:// ]]; then
    echo "${BEE_HUBS_CACHE_PATH}/$(basename "${url}")"
  else
    bee::log_warn "Unsupported hub url: ${url}"
  fi
}
