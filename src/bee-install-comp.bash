plugins="$(bee::source "bee-hubs" --list)"
if (( ! $# || $# == 1 && COMP_PARTIAL )); then
  comps=(--force "${plugins}")
  compgen -W "${comps[*]}" -- "${1:-}"
else
  echo "${plugins}"
fi
