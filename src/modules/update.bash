# bee::help
# update ; update bee to the latest version
#    print [--cached] ; show latest version [cache locally]
# bee::help

bee::update::comp() {
  echo "print"
}

bee::update() {
  if (($#)); then
    case "$1" in
      print) shift; bee::update::print "$@" ;;
      *) bee::usage ;;
    esac
  else
    pushd "${BEE_SYSTEM_HOME}" > /dev/null || exit 1
      git pull origin main
      bee::log "bee is up-to-date and ready to bzzzz"
    popd > /dev/null || exit 1
  fi
}

bee::update::print() {
  while (($#)); do case "$1" in
    --cached) bee::update::print_cached; return ;;
    --) shift; break ;;
    *) break ;;
  esac; shift; done

  if (($#)); then
    bee::usage
  else
    curl -fsSL "${BEE_LATEST_VERSION_PATH}"
  fi
}

bee::update::print_cached() {
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
