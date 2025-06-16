main() {
  local plugins
  plugins="$(bee::source "bee-hubs" --list)"
  if (( ! $# || $# == 1 && COMP_PARTIAL )); then
    local -a comps=(--force "${plugins}")
    compgen -W "${comps[*]}" -- "${1:-}"
  else
    echo "${plugins}"
  fi
}

main "$@"
