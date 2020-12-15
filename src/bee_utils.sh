#!/usr/bin/env bash

internal_commands() {
  local internal_commands=()
  for command in $(compgen -A function); do
    local help_var="${command}_internal_help[@]"
    if [[ -v "${help_var}" ]]; then
      internal_commands+=("${command}")
    fi
  done
  echo "${internal_commands[@]}"
}

assert_file() {
  if [[ ! -f "${!1}" ]]; then
    echo "❌ ASSERT ${1}: file not found: ${!1}" >&2
    exit 1
  fi
}

require() {
  command -v "${1}" &> /dev/null || {
    log_error "${1} not found! ${1} is required."
    exit 1
  }
}

source_plugins() {
  local found_all=true
  for plugin_name in "$@"; do
    local found=false
    for dir in "${BEE_PLUGINS[@]}"; do
      local plugin_path="${dir}/${plugin_name}/${plugin_name}.sh"
      if [[ -f "${plugin_path}" ]]; then
        source "${plugin_path}"
        found=true
        break
      fi
    done

    if [[ ${found} == false ]]; then
      found_all=false
      log_error "Could not find plugin ${plugin_name}"
    fi
  done

  if [[ ${found_all} == false ]]; then
    exit 1
  fi
}
