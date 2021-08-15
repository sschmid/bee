# bee::help
# hub
#    pull [<urls>] ; update hubs
#    install [<plugins>] ; install plugins
# bee::help

BEE_HUBS_CACHE_PATH="${BEE_CACHES_PATH}/hubs"

bee::hub::comp() {
  echo "ls"
  echo "pull"
  echo "install"
}

bee::hub() {
  if (($#)); then
    case "$1" in
      ls) shift; bee::hub::ls "$@" ;;
      pull) shift; bee::hub::pull "$@" ;;
      install) shift; echo "Installing"; bee::hub::install "$@" ;;
      *) bee::usage ;;
    esac
  else
    bee::usage
  fi
}

bee::hub::ls() {
  local cache_path
  local -a plugins
  local -i i n
  for url in "${@:-"${BEE_HUBS[@]}"}"; do
    cache_path="$(bee::hub::to_cache_path "${url}")"
    if [[ -n "$cache_path" ]]; then
      echo "${url}"
      if [[ -d "${cache_path}" ]]; then
        mapfile -t plugins < <(ls "${cache_path}")
        n=${#plugins[@]}
        for ((i = 0; i < n; i++)); do
          if ((i == n - 1)); then
            echo "└── ${plugins[i]}"
          else
            echo "├── ${plugins[i]}"
          fi
        done
        echo
      fi
    fi
  done
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
  bee::hub::install_recursively "" "$@"
}

bee::hub::install_recursively() {
  local indent="$1"
  shift
  local -a plugins=("$@") missing=()
  local plugin plugin_name plugin_version cache_path spec_path bullet
  local -i i n=${#plugins[@]} found=0
  for ((i = 0; i < n; i++)); do
    found=0
    plugin="${plugins[i]}"
    plugin_name="${plugin%:*}"
    plugin_version="${plugin##*:}"
    if ((i == n - 1)); then bullet="└── "; else bullet="├── "; fi
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
          echo "${indent}${bullet}${plugin_name}:${plugin_version}"
        else
          local git tag deps
          while read -r git tag deps; do
            git -c advice.detachedHead=false clone -q --depth 1 --branch "${tag}" "${git}" "${plugin_path}"
            echo -e "${indent}${bullet}\033[32m${plugin_name}:${plugin_version} ✔︎ (${url})\033[0m"
            # shellcheck disable=SC2086
            if [[ -n "${deps}" ]]; then
              if ((i == n - 1)); then
                bee::hub::install_recursively "${indent}    " ${deps}
              else
                bee::hub::install_recursively "${indent}│   " ${deps}
              fi
            fi
          done < <(jq -r '[.git, .tag, .dependencies[]?] | @tsv' "${spec_path}")
        fi
        break
      fi
    done
    if ((!found)); then
      missing+=("${plugin}")
      echo -e "${indent}${bullet}\033[31m${plugin} ✗\033[0m"
    fi
  done
  if ((${#missing[@]})); then
    for m in "${missing[@]}"; do
      bee::log_error "Couldn't install plugin: ${m}"
    done
    exit 1
  fi
}

bee::hub::to_cache_path() {
  case "$1" in
    https://*) echo "${BEE_HUBS_CACHE_PATH}/$(dirname "${1#https://}")/$(basename "$1" .git)" ;;
    git://*) echo "${BEE_HUBS_CACHE_PATH}/$(dirname "${1#git://}")/$(basename "$1" .git)" ;;
    git@*) local path="${1#git@}"; echo "${BEE_HUBS_CACHE_PATH}/$(dirname "${path/://}")/$(basename "$1" .git)" ;;
    ssh://*) local path="${1#ssh://}"; echo "${BEE_HUBS_CACHE_PATH}/$(dirname "${path#git@}")/$(basename "$1" .git)" ;;
    file://*) echo "${BEE_HUBS_CACHE_PATH}/$(basename "$1")" ;;
    *) bee::log_warn "Unsupported hub url: $1" ;;
  esac
}
