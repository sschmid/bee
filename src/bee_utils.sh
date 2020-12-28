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

resolve_plugins() {
  local found_all=true
  for plugin in "$@"; do
    local plugin_name="${plugin%:*}"
    local plugin_version="${plugin##*:}"
    local found=false
    if [[ "${plugin_name}" == "${plugin_version}" ]]; then
      for path in "${BEE_PLUGINS[@]}"; do
        local plugin_path="${path}/${plugin_name}"
        if [[ -d "${plugin_path}" ]]; then
          local versions=("${plugin_path}/"*)
          plugin_version="$(basename ${versions[@]} | sort -V | tail -n 1)"
          found=true
          echo "${plugin_name}:${plugin_version}:${plugin_path}"
          break
        fi
      done
    else
      for path in "${BEE_PLUGINS[@]}"; do
        local plugin_path="${path}/${plugin_name}"
        if [[ -d "${plugin_path}/${plugin_version}" ]]; then
          found=true
          echo "${plugin_name}:${plugin_version}:${plugin_path}"
          break
        fi
      done
    fi

    if [[ ${found} == false ]]; then
      found_all=false
      log_error "Could not find plugin ${plugin}"
    fi
  done

  if [[ ${found_all} == false ]]; then
    exit 1
  fi
}

source_plugins() {
  # TODO: remove when expired
  source "${BEE_SYSTEM_HOME}/src/bee_migration_0390.sh"

  for plugin in $(resolve_plugins $@); do
    local plugin_id="${plugin%:*}"
    local plugin_name="${plugin_id%:*}"
    local plugin_version="${plugin_id##*:}"
    local plugin_path="${plugin##*:}"

    # TODO: remove when expired
    plugin_version="$(bee_migration_0390 "${plugin_name}" "${plugin_version}")"

    source "${plugin_path}/${plugin_version}/${plugin_name}.sh"
  done
}
