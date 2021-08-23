# bee::help
# cache : show cache path
# cache rm : delete cache
# bee::help

bee::cache::comp() {
  echo "rm"
}

bee::cache() {
  if (($#)); then
    case "$1" in
      rm) rm -rf "${BEE_CACHES_PATH}" ;;
      *) bee::usage ;;
    esac
  else
    echo "${BEE_CACHES_PATH}"
  fi
}
