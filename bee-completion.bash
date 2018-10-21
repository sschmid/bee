#!/usr/bin/env bash

_bee_completions() {
  local wordlist="plugins commands new res version update wiki ❤️"
  wordlist+=" $(bee commands)"
  COMPREPLY=($(compgen -W "${wordlist}" "${COMP_WORDS[1]}"))
}

complete -F _bee_completions bee
