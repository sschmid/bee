########################################
# List plugins from hubs
# Arguments:
#   [--all] | [--list] [url ...]
########################################
main() {
  local -i show_all=0 list=0
  while (( $# )); do
    case "$1" in
      --all) show_all=1; shift ;;
      --list) list=1; shift ;;
      --) shift; break ;;
      *) break ;;
    esac
  done

  local url cache_path
  if (( list )); then
    local cache_path
    for url in "${@:-"${BEE_HUBS[@]}"}"; do
      cache_path="$(bee::to_cache_path "${url}")"
      if [[ -n "${cache_path}" ]]; then
        cache_path="${BEE_HUBS_CACHE_PATH}/${cache_path}"
        [[ ! -d "${cache_path}" ]] || ls "${cache_path}"
      fi
    done
  else
    local plugin_name plugin_version indent bullet
    local -a plugins versions
    local -i i j n m
    for url in "${@:-"${BEE_HUBS[@]}"}"; do
      cache_path="$(bee::to_cache_path "${url}")"
      if [[ -n "${cache_path}" ]]; then
        cache_path="${BEE_HUBS_CACHE_PATH}/${cache_path}"
        echo "${url}"
        if [[ -d "${cache_path}" ]]; then
          mapfile -t plugins < <(ls "${cache_path}")
          n=${#plugins[@]}
          for (( i = 0; i < n; i++ )); do
            plugin_name="${plugins[i]}"
            (( i == n - 1 )) && bullet="└── " || bullet="├── "
            echo "${bullet}${plugin_name}"

            if (( show_all )); then
              mapfile -t versions < <(find "${cache_path}/${plugin_name}" -maxdepth 1 -mindepth 1 -type d | LC_ALL=C sort -V)
              m=${#versions[@]}
              for (( j = 0; j < m; j++ )); do
                plugin_version="$(basename -- "${versions[j]}")"
                (( i == n - 1 )) && indent="    " || indent="│    "
                (( j == m - 1 )) && bullet="└── " || bullet="├── "
                echo "${indent}${bullet}${plugin_version}"
              done
            fi
          done
          echo
        fi
      fi
    done
  fi
}

main "$@"
