#!/usr/bin/env bash

BEE_REGISTRIES_HOME="${HOME}/.bee/caches/registries"
BEE_PLUGINS_HOME="${HOME}/.bee/caches/plugins"

################################################################################
# registries
################################################################################

resolve_registry_cache() {
  local registry="$1"
  if [[ "${registry}" =~ ^git@.* ]]; then
    echo "${BEE_REGISTRIES_HOME}/$(dirname "${registry#git@}")/$(basename "${registry}" .git)"
  elif [[ "${registry}" =~ ^file:// ]]; then
    echo "${BEE_REGISTRIES_HOME}/$(basename "${registry}")"
  else
    log_warn "Unsupported registry url: ${registry}"
  fi
}

resolve_registry_caches() {
  for registry in "${BEE_PLUGINS_REGISTRIES[@]}"; do
    resolve_registry_cache "${registry}"
  done
}

update_registries() {
  log "Updating registries"
  for registry in "${BEE_PLUGINS_REGISTRIES[@]}"; do
    local cache="$(resolve_registry_cache "${registry}")"
    if [[ -n "${cache}" ]]; then
      if [[ ! -d "${cache}" ]]; then
        git clone "${registry}" "${cache}"
      else
        pushd "${cache}" > /dev/null
          git pull
        popd > /dev/null
      fi
    fi
  done
}

list() {
  update_registries
  for cache in $(resolve_registry_caches); do
    local plugins=("${cache}"/*/)
    if [[ -d "${plugins}" ]]; then
      basename -a "${plugins[@]}"
    fi
  done
}

################################################################################
# plugins
################################################################################

resolve_plugin_specs() {
  local caches=($(resolve_registry_caches))
  local found_all=true
  for plugin in "$@"; do
    local plugin_name="${plugin%:*}"
    local plugin_version="${plugin##*:}"
    local found=false
    if [[ "${plugin_name}" == "${plugin_version}" ]]; then
      # find latest
      for cache in "${caches[@]}"; do
        local plugin_path="${cache}/${plugin_name}"
        if [[ -d "${plugin_path}" ]]; then
          local versions=("${plugin_path}"/*/)
          if [[ -d "${versions}" ]]; then
            plugin_version="$(basename -a "${versions[@]}" | sort -V | tail -n 1)"
            found=true
            echo "${plugin_path}/${plugin_version}/plugin.sh"
            break
          fi
        fi
      done
    else
      for cache in "${caches[@]}"; do
        local plugin_path="${cache}/${plugin_name}"
        if [[ -d "${plugin_path}/${plugin_version}" ]]; then
          found=true
          echo "${plugin_path}/${plugin_version}/plugin.sh"
          break
        fi
      done
    fi

    if [[ ${found} == false ]]; then
      found_all=false
      log_warn "Could not find plugin ${plugin}"
    fi
  done

  if [[ ${found_all} == false ]]; then
    exit 1
  fi
}

unload_plugin_spec() {
  unset BEE_PLUGIN_NAME
  unset BEE_PLUGIN_VERSION
  unset BEE_PLUGIN_LICENSE
  unset BEE_PLUGIN_HOMEPAGE
  unset BEE_PLUGIN_AUTHORS
  unset BEE_PLUGIN_SUMMARY
  unset BEE_PLUGIN_SOURCE
  unset BEE_PLUGIN_TAG
}

info() {
  for plugin in $(resolve_plugin_specs $1); do
    source "${plugin}"
    echo "name: | ${BEE_PLUGIN_NAME}
version: | ${BEE_PLUGIN_VERSION}
license: | ${BEE_PLUGIN_LICENSE}
homepage: | ${BEE_PLUGIN_HOMEPAGE}
authors: | ${BEE_PLUGIN_AUTHORS}
summary: | ${BEE_PLUGIN_SUMMARY}
source: | ${BEE_PLUGIN_SOURCE}
tag: | ${BEE_PLUGIN_TAG}" | column -s '|' -t
    unload_plugin_spec
  done
}

install() {
  for plugin in $(resolve_plugin_specs "${PLUGINS[@]}"); do
    source "${plugin}"
    local path="${BEE_PLUGINS_HOME}/${BEE_PLUGIN_NAME}/${BEE_PLUGIN_VERSION}"
    if [[ ! -d "${path}" ]]; then
      log "Installing ${BEE_PLUGIN_NAME}"
      git -c advice.detachedHead=false clone --depth 1 --branch "${BEE_PLUGIN_TAG}" "${BEE_PLUGIN_SOURCE}" "${path}"
    fi
    unload_plugin_spec
  done
}
