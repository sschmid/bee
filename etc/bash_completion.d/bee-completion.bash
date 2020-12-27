#!/usr/bin/env bash

_bee_completions() {
  local firstWord="${COMP_WORDS[1]}"
  local lastWord="${COMP_WORDS[-1]}"
  if [[ $COMP_CWORD == 1 ]]; then
    local words="$(bee builtin_commands) $(bee plugins) $(bee commands)"
    COMPREPLY=($(compgen -W "${words}" "${firstWord}"))
  else
    case "${firstWord}" in
      "commands" | "deps" | "donate" | "plugins" | "uninstall" | "update" | "version" | "wiki")
        ;;

      "help")
        if (( $COMP_CWORD == 2 )); then
          COMPREPLY=($(compgen -W "$(bee plugins)" "${lastWord}"))
        fi
        ;;

      "new" | "res")
        COMPREPLY=($(compgen -W "$(bee plugins)" "${lastWord}"))
        ;;

      *)
        if [[ $COMP_CWORD == 2 ]]; then
          local plugins="$(bee plugins)"
          for plugin_name in ${plugins}; do
            if [[ "${firstWord}" == "${plugin_name}" ]]; then
              COMPREPLY=($(compgen -W "$(bee "${firstWord}" commands)" "${lastWord}"))
              return
            fi
          done

          COMPREPLY=($(compgen -A file "${lastWord}"))
        else
          COMPREPLY=($(compgen -A file "${lastWord}"))
        fi
        ;;
    esac
  fi
}

complete -F _bee_completions bee
