# bee::help
# cache : show cache path
# cache rm : delete cache
# bee::help

bee::cache::comp() {
  local -i partial="$1"; shift
  if ((!$# || $# == 1 && partial)); then
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
