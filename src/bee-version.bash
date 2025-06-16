########################################
# Print the version of bee
# Arguments:
#   [--latest] [--cached]
########################################
main() {
  local -i latest=0 cached=0
  while (( $# )); do
    case "$1" in
      --latest) latest=1; shift ;;
      --cached) cached=1; shift ;;
      --) shift; break ;; *) break ;;
    esac
  done

  if (( $# )); then
    bee::source "bee-help"
    exit 1
  fi

  if (( latest )); then
    if (( cached )); then
      mkdir -p "${BEE_CACHE_PATH}"
      local cache_file="${BEE_CACHE_PATH}/.bee_latest_version_cache"
      local version
      local -i last_ts now delta
      now=$(date +%s)
      if [[ -f "${cache_file}" ]]; then
        IFS=, read -r last_ts version < "${cache_file}"
      else
        last_ts=0
      fi
      delta=$(( now - last_ts ))
      if (( delta > BEE_LATEST_VERSION_CACHE_EXPIRE )); then
        version="$(curl -fsSL "${BEE_LATEST_VERSION_PATH}")"
        echo "${now},${version}" > "${cache_file}"
      fi
      echo "${version}"
    else
      curl -fsSL "${BEE_LATEST_VERSION_PATH}"
    fi
  else
    cat "${BEE_HOME}/version.txt"
  fi
}

main "$@"
