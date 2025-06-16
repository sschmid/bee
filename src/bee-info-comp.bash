main() {
  if (( ! $# || $# == 1 && COMP_PARTIAL )); then
    {
      bee::source "bee-hubs" --list
      bee::comp_plugins
    } | awk '!line[$0]++'
  fi
}

main "$@"
