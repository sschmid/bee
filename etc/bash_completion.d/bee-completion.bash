#!/usr/bin/env bash

_bee_completions() {
  local firstWord="${COMP_WORDS[1]}"
  local lastWord="${COMP_WORDS[-1]}"
  if [[ $COMP_CWORD == 1 ]]; then
    local words="$(bee builtin_commands) $(bee plugins -a) $(bee commands)"
    COMPREPLY=($(compgen -W "${words}" "${firstWord}"))
  else
    case "${firstWord}" in
      "donate" | "plugins" | "uninstall" | "update" | "version" | "wiki")
        ;;

      "commands" | "deps" | "depstree" | "install" | "new" | "res")
        COMPREPLY=($(compgen -W "$(bee plugins -a)" "${lastWord}"))
        ;;

      "changelog" | "info" | "help")
        if (( $COMP_CWORD == 2 )); then
          COMPREPLY=($(compgen -W "$(bee plugins -a)" "${lastWord}"))
        fi
        ;;

      "pull")
        COMPREPLY=($(compgen -W "$(bee log_var BEE_PLUGIN_REGISTRIES[@])" "${lastWord}"))
        ;;

      "hash" | "lint")
        if (( $COMP_CWORD == 2 )); then
          COMPREPLY=($(compgen -f "${lastWord}"))
        fi
        ;;

      *)
        if [[ $COMP_CWORD == 2 ]]; then
          local plugins="$(bee plugins -a)"
          for plugin in ${plugins}; do
            if [[ "${firstWord}" == "${plugin}" ]]; then
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

complete -o filenames -F _bee_completions bee
