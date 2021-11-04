# bee::help
# hub install [<plugins>] : install plugins
# hub ls [-a | --all] [<urls>] : list hubs and their plugins (--all versions)
# hub plugins [<urls>] : list plugins
# hub pull [<urls>] : update hubs
# bee::help

BEE_HUBS_CACHE_PATH="${BEE_CACHES_PATH}/hubs"

bee::hub::comp() {
  local -i partial="$1"; shift
  local cmd="${1:-}"
  if ((!$# || $# == 1 && partial)); then
    local comps=(install ls plugins pull)
    local IFS=' '
    compgen -W "${comps[*]}" -- "${cmd}"
  else
    case "${cmd}" in
      install) bee::hub::plugins ;;
      ls) shift; bee::hub::ls::comp "${partial}" "$@" ;;
      plugins) echo "${BEE_HUBS[*]}" ;;
      pull) shift; bee::hub::pull::comp "${partial}" "$@" ;;
    esac
  fi
}

bee::hub::ls::comp() {
  local -i partial="$1"; shift
  if ((!$# || $# == 1 && partial)); then
    local cmd="${1:-}"
    local comps=("-a --all ${BEE_HUBS[*]}")
    local IFS=' '
    compgen -W "${comps[*]}" -- "${cmd}"
  else
    echo "${BEE_HUBS[*]}"
  fi
}

bee::hub::pull::comp() {
  local -i partial="$1"; shift
  if ((!$# || $# == 1 && partial)); then
    local cmd="${1:-}"
    local comps=("-f --force ${BEE_HUBS[*]}")
    local IFS=' '
    compgen -W "${comps[*]}" -- "${cmd}"
  else
    echo "${BEE_HUBS[*]}"
  fi
}

bee::hub() {
  if (($#)); then
    case "$1" in
      ls) shift; bee::hub::ls "$@" ;;
      plugins) shift; bee::hub::plugins "$@" ;;
      pull) shift; bee::hub::pull "$@" ;;
      install) shift; echo "Installing"; bee::hub::install "$@" ;;
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
    cache_path="$(bee::hub::to_cache_path "${url}")"
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
    cache_path="$(bee::hub::to_cache_path "${url}")"
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
    date +%s > "${cache_file}"
  fi
}

bee::hub::install() {
  bee::hub::install_recursively "" "$@"
}

bee::hub::install_recursively() {
  local indent="$1"; shift
  local -a plugins=("$@") missing=()
  local plugin plugin_name plugin_version cache_path spec_path bullet
  local -i i n=${#plugins[@]} found=0
  for ((i = 0; i < n; i++)); do
    found=0
    plugin="${plugins[i]}"
    ((i == n - 1)) && bullet="└── " || bullet="├── "
    for url in "${BEE_HUBS[@]}"; do
      cache_path="$(bee::hub::to_cache_path "${url}")"
      while read -r plugin_name plugin_version spec_path; do
        found=1
        local plugin_path="${BEE_CACHES_PATH}/plugins/${plugin_name}/${plugin_version}"
        if [[ -d "${plugin_path}" ]]; then
          echo "${indent}${bullet}${plugin_name}:${plugin_version}"
        else
          local git tag deps
          while read -r git tag deps; do
            git -c advice.detachedHead=false clone -q --depth 1 --branch "${tag}" "${git}" "${plugin_path}"
            echo -e "${indent}${bullet}${BEE_COLOR_SUCCESS}${BEE_CHECK_SUCCESS}︎ ${plugin_name}:${plugin_version} (${url})${BEE_COLOR_RESET}"
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
