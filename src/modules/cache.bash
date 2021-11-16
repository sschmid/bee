# bee::help
# cache : print cache path
# cache rm : delete cache
# bee::help

bee::cache::comp() {
  if ((!$# || $# == 1 && COMP_PARTIAL)); then
    local cmd="${1:-}" comps=(rm)
    local IFS=' '
    compgen -W "${comps[*]}" -- "${cmd}"
  fi
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
