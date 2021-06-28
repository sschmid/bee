#!/usr/bin/env bash

# shellcheck disable=SC2207
_bee_completions() {
  local first_word="${COMP_WORDS[1]}"
  if ((COMP_CWORD == 1)); then
    COMPREPLY=($(compgen -W "$(bee --batch "bee::comp_modules" "bee::comp_plugins")" "${first_word}"))
  elif ((COMP_CWORD == 2)); then
    local second_word="${COMP_WORDS[2]}"
    COMPREPLY=($(compgen -W "$(bee bee::comp_module_or_plugin "${first_word}")" "${second_word}"))
  else
    :
  fi
}

complete -F _bee_completions bee
