#!/usr/bin/env bash

_bee_completions() {
  if [[ $COMP_CWORD == 1 ]]; then
    COMPREPLY=("$(compgen -W "$(bee internal_commands) $(bee plugins) $(bee commands)")")
  else
    local word="${COMP_WORDS[1]}"
    case "${word}" in
      "commands" | "deps" | "donate" | "plugins" | "update" | "version" | "wiki")
      ;;

      "help")
        if (( $COMP_CWORD == 2 )); then
          COMPREPLY=("$(compgen -W "$(bee plugins)")")
        fi
        ;;

      "new" | "res")
        COMPREPLY=("$(compgen -W "$(bee plugins)")")
        ;;

      *)
        if [[ $COMP_CWORD == 2 ]]; then
          local plugins="$(bee plugins)"
          for plugin_name in ${plugins}; do
            if [[ "${word}" == "${plugin_name}" ]]; then
              COMPREPLY=("$(compgen -W "$(bee "${word}" commands)")")
              return
            fi
          done

          COMPREPLY=("$(compgen -A file "${word}")")
        else
          COMPREPLY=("$(compgen -A file "${word}")")
        fi
        ;;
    esac
  fi
}

complete -F _bee_completions bee
