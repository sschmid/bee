#!/usr/bin/env bash

assert_file() {
  local file="${!1}"
  if [[ ! -f "${file}" ]]; then
    echo "❌ ASSERT ${1}: file not found: ${file}" >&2
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
    for path in "${BEE_PLUGINS[@]}"; do
      local plugin_path="${path}/${plugin_name}/${plugin_name}.sh"
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
