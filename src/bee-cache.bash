########################################
# Open or clear cache directories
# Arguments:
#   None | --clear [directory]
########################################
main() {
  if (( $# )); then
    case "$1" in
      --clear)
        rm -rf "${BEE_CACHE_PATH}${2:+"/$2"}"
        ;;
      *)
        bee::source "bee-help"
        exit 1
        ;;
    esac
  else
    os_open "${BEE_CACHE_PATH}"
  fi
}

main "$@"
