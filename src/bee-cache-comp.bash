main() {
  if (( ! $# || $# == 1 && COMP_PARTIAL )); then
    echo --clear
  elif (( $# == 1 || $# == 2 && COMP_PARTIAL )); then
    case "${1:-}" in
      --clear) [[ ! -d "${BEE_CACHE_PATH}" ]] || ls "${BEE_CACHE_PATH}" ;;
    esac
  fi
}

main "$@"
