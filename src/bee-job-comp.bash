main() {
  local -a comps=(--logfile --time)
  while (( $# )); do
    case "$1" in
      --logfile) comps=("${comps[@]/--logfile/}"); shift ;;
      --time) comps=("${comps[@]/--time/}"); shift ;;
      --) shift; break ;;
      *) break ;;
    esac
  done
  compgen -W "${comps[*]}" -- "${1:-}"
}

main "$@"
