# bee::help
# update ; update bee to the latest version
#   print [--cached] ; show latest version [cache locally]
# bee::help

bee::update() {
  while (($# > 0)); do case "$1" in
    --read-latest-version) bee::update::read_latest_version; return ;;
    --read-latest-version-cached) bee::update::read_latest_version_cached; return ;;
    --) shift; break ;;
    *) break ;;
  esac; shift; done

  if (($# == 0)); then
    pushd "${BEE_SYSTEM_HOME}" > /dev/null || exit 1
      git pull origin main
      bee::log "bee is up-to-date and ready to bzzzz"
    popd > /dev/null || exit 1
  else
    bee::usage
  fi
}

bee::update::read_latest_version() {
  curl -fsSL "${BEE_LATEST_VERSION_PATH}"
}

bee::update::read_latest_version_cached() {
  mkdir -p "${BEE_CACHES_PATH}"
  local -i last_ts now delta
  local cache cache_file="${BEE_CACHES_PATH}/.bee_latest_version_cache"
  [[ ! -f "${cache_file}" ]] && echo "0,0" > "${cache_file}"
  now=$(date +%s)
  cache="$(cat "${cache_file}")"
  last_ts="${cache%%,*}"
  delta=$((now - last_ts))
  if ((delta > BEE_LATEST_VERSION_CACHE_EXPIRE)); then
    local latest
    latest="$(curl -fsSL "${BEE_LATEST_VERSION_PATH}")"
    echo "${now},${latest}" > "${cache_file}"
    echo "${latest}"
  else
    echo "${cache##*,}"
  fi
}
