# bee theme customization:
# set vars in your your ~/.zshrc to enable features
# export BEE_PROMPT_LOCK=1       # print missing plugins based on Beefile.lock
                                 # which indicates that you should run 'bee install'
# export BEE_PROMPT_OUTDATED=1   # print outdated plugins 
# export BEE_PROMPT_VERSION=1    # print project's bee version
# unset vars to deactivate features

bee_prompt_info() {
  local prompt="" output newline=$'\n'
  if [[ -v BEE_PROMPT_LOCK && -v BEE_PROMPT_OUTDATED ]]; then
    output="$(bee --batch --allow-fail "plugins --lock" "plugins --outdated")"
    [[ -n "${output}" ]] && prompt+="${output}${newline}"
  else
    if [[ -v BEE_PROMPT_LOCK ]]; then
      output="$(bee plugins --lock)"
      [[ -n "${output}" ]] && prompt+="${output}${newline}"
    fi
    if [[ -v BEE_PROMPT_OUTDATED ]]; then
      output="$(bee plugins --outdated)"
      [[ -n "${output}" ]] && prompt+="${output}${newline}"
    fi
  fi
  if [[ -v BEE_PROMPT_VERSION ]]; then
    output="$(bee prompt)" && prompt+="%{$fg[yellow]%}${output} "
  fi
  echo "${prompt}%{$fg_bold[blue]%}%c"
}

PROMPT='$(bee_prompt_info)$(git_prompt_info)'
PROMPT+='%(?:%{$fg[green]%}:%{$fg[red]%})%(#:#:$)%{$reset_color%} '

ZSH_THEME_GIT_PROMPT_PREFIX="%{$fg[red]%}("
ZSH_THEME_GIT_PROMPT_SUFFIX=")"
ZSH_THEME_GIT_PROMPT_DIRTY="%{$fg[yellow]%}*%{$fg[red]%}"
ZSH_THEME_GIT_PROMPT_CLEAN=""
