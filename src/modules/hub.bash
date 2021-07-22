BEE_HUBS_CACHE_PATH="${BEE_CACHES_PATH}/hubs"

bee::hub() {
  if (($# >= 1)); then
    case "$1" in
      update)
        mkdir -p "${BEE_HUBS_CACHE_PATH}"
        local cache_path
        for url in "${BEE_HUBS[@]}"; do
          cache_path="$(bee::hub::to_cache_path "${url}")"
          if [[ -n "${cache_path}" ]]; then
            if [[ -d "${cache_path}" ]]; then
              pushd "${cache_path}" > /dev/null || exit 1
                git pull &
              popd > /dev/null || exit 1
            else
              git clone "${url}" "${cache_path}" &
            fi
          fi
        done
        wait
        ;;
      *) bee::usage ;;
    esac
  else
    bee::usage
  fi
}

bee::hub::to_cache_path() {
  local url="$1"
  if [[ "${url}" =~ ^https:// ]]; then
    echo "${BEE_HUBS_CACHE_PATH}/$(dirname "${url#https://}")/$(basename "${url}" .git)"
  elif [[ "${url}" =~ ^git@ ]]; then
    local path="${url#git@}"
    echo "${BEE_HUBS_CACHE_PATH}/$(dirname "${path/://}")/$(basename "${url}" .git)"
  elif [[ "${url}" =~ ^file:// ]]; then
    echo "${BEE_HUBS_CACHE_PATH}/$(basename "${url}")"
  fi
}
