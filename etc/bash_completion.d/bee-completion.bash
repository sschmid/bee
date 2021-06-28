#!/usr/bin/env bash

# shellcheck disable=SC2207
_bee_completions() {
  if ((COMP_CWORD == 1)); then
    COMPREPLY=($(compgen -W "$(bee --batch "bee::comp_modules" "bee::comp_plugins")" "${COMP_WORDS[1]}"))
  elif ((COMP_CWORD == 2)); then
    COMPREPLY=($(compgen -W "$(bee bee::comp_module_or_plugin "${COMP_WORDS[1]}")" "${COMP_WORDS[2]}"))
  else
    :
  fi
}

complete -F _bee_completions bee
