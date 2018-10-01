#!/usr/bin/env bash

_bee_completions() {
  COMPREPLY=($(compgen -W "$(bee commands)" "${COMP_WORDS[1]}"))
  if [[ "${#COMPREPLY[@]}" -eq 0 ]]; then
    COMPREPLY=($(compgen -W "plugins commands new version update wiki" "${COMP_WORDS[1]}"))
  fi
}

complete -F _bee_completions bee
