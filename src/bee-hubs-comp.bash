if (( ! $# || $# == 1 && COMP_PARTIAL )); then
  comps=(--all --list "${BEE_HUBS[*]}")
  compgen -W "${comps[*]}" -- "${1:-}"
else
  echo "${BEE_HUBS[*]}"
fi
