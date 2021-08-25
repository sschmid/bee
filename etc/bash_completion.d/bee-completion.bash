#!/usr/bin/env bash

_bee_completions() {
  local cur=${COMP_WORDS[$COMP_CWORD]:-}
  # shellcheck disable=SC2206
  local words=(${COMP_WORDS[@]})
  # shellcheck disable=SC2207
  if ((COMP_CWORD == 1)); then # e.g. bee plu
    COMPREPLY=($(compgen -W "$(bee -b "bee::comp_modules" "bee::comp_plugins")" -- "${cur}"))
  else # e.g. bee hub inst
    # shellcheck disable=SC2206
    COMPREPLY=($(compgen -W "$(bee bee::comp_module_or_plugin "${COMP_WORDS[1]}" "${words[@]:2}")" -- "${cur}"))
  fi
}

complete -F _bee_completions bee
