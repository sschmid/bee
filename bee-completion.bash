#!/usr/bin/env bash

_bee_completions() {
  local word="${COMP_WORDS[1]}"
  if [[ $COMP_CWORD -lt 2 ]]; then
    local wordlist="help plugins commands new res version update wiki ❤️"
    wordlist+=" $(bee plugins)"
    wordlist+=" $(bee commands)"
    COMPREPLY=($(compgen -W "${wordlist}" "${word}"))
  else
    case "${word}" in
      "plugins" | "commands" | "version" | "update" | "wiki" | ❤️)
        ;;
      "help")
        if [[ $COMP_CWORD -eq 2 ]]; then
          COMPREPLY=($(compgen -W "$(bee plugins)" "${word}"))
        fi
        ;;
      "new" | "res")
        COMPREPLY=($(compgen -W "$(bee plugins)" "${word}"))
        ;;
      *)
        if [[ $COMP_CWORD -eq 2 ]]; then
          local plugins=($(bee plugins))
          for p in "${plugins[@]}"; do
            if [[ "${word}" == "$p" ]]; then
              COMPREPLY=($(compgen -W "$(bee ${word} commands)" "${word}"))
              break
            fi
          done
        else
          COMPREPLY=$(compgen -W "$(ls -a)" -- "${word}")
        fi
        ;;
    esac
  fi
}

complete -F _bee_completions bee
