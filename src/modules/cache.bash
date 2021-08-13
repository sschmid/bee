# bee::help
# cache ; show cache path
#   rm ; delete cache
# bee::help

bee::cache() {
  if (($#)); then
    case "$1" in
      rm) shift; rm -rf "${BEE_CACHES_PATH}" ;;
      *) bee::usage ;;
    esac
  else
    echo "${BEE_CACHES_PATH}"
  fi
}
