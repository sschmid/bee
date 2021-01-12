#!/usr/bin/env bash

# ################################################################################
# # utils
# ################################################################################

assert_file() {
  local file="${!1}"
  if [[ ! -f "${file}" ]]; then
    echo "❌ ASSERT $1: file not found: ${file}" >&2
    exit 1
  fi
}

require() {
  command -v "$1" &> /dev/null || {
    log_error "$1 not found! $1 is required."
    exit 1
  }
}

################################################################################
# registries
################################################################################

BEE_REGISTRIES_HOME="${HOME}/.bee/caches/registries"
BEE_PLUGINS_HOME="${HOME}/.bee/caches/plugins"

resolve_registry_cache() {
  local url="$1"
  if [[ "${url}" =~ ^git@.* ]]; then
    echo "${BEE_REGISTRIES_HOME}/$(dirname "${url#git@}")/$(basename "${url}" .git)"
  elif [[ "${url}" =~ ^file:// ]]; then
    echo "${BEE_REGISTRIES_HOME}/$(basename "${url}")"
  else
    log_warn "Unsupported registry url: ${url}"
  fi
}

resolve_registry_caches() {
  for url in "${BEE_PLUGIN_REGISTRIES[@]}"; do
    resolve_registry_cache "${url}"
  done
}

bee_help_pull=(
  "pull | update all plugin registries"
  "pull <urls> | update plugin registries"
)
pull() {
  for url in "${@-"${BEE_PLUGIN_REGISTRIES[@]}"}"; do
    local cache="$(resolve_registry_cache "${url}")"
    if [[ -n "${cache}" ]]; then
      if [[ -d "${cache}" ]]; then
        pushd "${cache}" > /dev/null
          git pull -q
        popd > /dev/null
      else
        git clone -q "${url}" "${cache}"
      fi
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

bee_help_info=("info | show plugin spec info")
info() {
  for spec in $(resolve_plugin_specs "$1"); do
    source "${spec}"
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

bee_help_install=(
  "install | install all enabled plugins"
  "install <plugins> | install plugins"
)
install() {
  pull
  for spec in $(resolve_plugin_specs "${@-"${PLUGINS[@]}"}"); do
    source "${spec}"
    local path="${BEE_PLUGINS_HOME}/${BEE_PLUGIN_NAME}/${BEE_PLUGIN_VERSION}"
    log "Installing ${BEE_PLUGIN_NAME} ${BEE_PLUGIN_VERSION}"
    if [[ ! -d "${path}" ]]; then
      git -c advice.detachedHead=false clone -q --depth 1 --branch "${BEE_PLUGIN_TAG}" "${BEE_PLUGIN_SOURCE}" "${path}"
    fi
    unload_plugin_spec
  done
}

source_plugins() {
  for spec in $(resolve_plugin_specs "$@"); do
    source "${spec}"
    local path="${BEE_PLUGINS_HOME}/${BEE_PLUGIN_NAME}/${BEE_PLUGIN_VERSION}/${BEE_PLUGIN_NAME}.sh"
    unload_plugin_spec
    if [[ -f "${path}" ]]; then
      source "${path}"
    fi
  done
}

bee_help_plugins=("plugins | list all plugins")
plugins() {
  for cache in $(resolve_registry_caches); do
    local plugins=("${cache}"/*/)
    if [[ -d "${plugins}" ]]; then
      basename -a "${plugins[@]}"
    fi
  done
}

bee_help_deps=("deps | list dependencies of enabled plugins")
deps() {
  missing=()
  local specs="$(resolve_plugin_specs "${PLUGINS[@]}")"
  for spec in ${specs}; do
    source "${spec}"
    local plugin_id="${BEE_PLUGIN_NAME}:${BEE_PLUGIN_VERSION}"
    local deps_func="${BEE_PLUGIN_NAME}::_deps"
    unload_plugin_spec
    if [[ $(command -v "${deps_func}") == "${deps_func}" ]]; then
      local dependencies=($(${deps_func} | tr ' ' '\n'))
      local status=""
      for dep in "${dependencies[@]}"; do
        local found_dep=false
        for s in ${specs}; do
          source "${s}"
          if [[ "${BEE_PLUGIN_NAME}" == "${dep}" || "${BEE_PLUGIN_NAME}:${BEE_PLUGIN_VERSION}" == "${dep}" ]]; then
            found_dep=true
            break
          fi
          unload_plugin_spec
        done

        if [[ ${found_dep} == true ]]; then
          status+=" \033[32m${dep}\033[0m"
        else
          status+=" \033[31m${dep}\033[0m"
          missing+=("${dep}")
        fi
      done

      echo -e "${plugin_id} =>${status}"
    fi
  done

  if [[ ${#missing[@]} -gt 0 ]]; then
    log_warn "Missing dependencies:"
    echo "${missing[*]}" | sort -u
  fi
}

bee_help_res=("res <plugins> | copy plugin resources into resources dir")
res() {
  for spec in $(resolve_plugin_specs "$@"); do
    source "${spec}"
    local resources_dir="${BEE_PLUGINS_HOME}/${BEE_PLUGIN_NAME}/${BEE_PLUGIN_VERSION}/resources"
    if [[ -d "${resources_dir}" ]]; then
      local target_dir="${BEE_RESOURCES}/${BEE_PLUGIN_NAME}"
      echo "Copying resources into ${target_dir}"
      mkdir -p "${target_dir}"
      cp -r "${resources_dir}/". "${target_dir}/"
    fi
    unload_plugin_spec
  done
}

# ################################################################################
# # commands
# ################################################################################

builtin_commands() {
  local commands=("$(compgen -v bee_help_)")
  echo "${commands[@]//bee_help_/}"
}

bee_help_update=("update | update bee to the latest version")
update() {
  pushd "${BEE_SYSTEM_HOME}" > /dev/null
    git pull -q
    log "bee is up-to-date and ready to bzzzz"
  popd > /dev/null
}

bee_help_version=("version | show the current bee version")
version() {
  local local_version="$(cat "${BEE_HOME}/version.txt")"
  echo "bee ${local_version}"
  local remote_version="$(curl -fsL https://raw.githubusercontent.com/sschmid/bee/master/version.txt)"
  if [[ -n "${remote_version}" ]]; then
    echo "latest: ${remote_version} (run 'bee update' to update to ${remote_version})"
  fi
}

bee_help_wiki=("wiki | open wiki")
wiki() {
  open "https://github.com/sschmid/bee/wiki"
}

bee_help_donate=("donate | bee is free, but powered by your donations")
donate() {
  open "https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=M7WHTWP4GE75Y"
}

new_bee() {
  if [[ -f .beerc ]]; then
    echo ".beerc already exists"
    exit 1
  else
    local local_version="$(cat "${BEE_HOME}/version.txt")"
    {
      echo '#!/usr/bin/env bash'
      echo "BEE_PROJECT=\"$(basename ${PWD})\""
      echo "BEE_VERSION=${local_version}"
      echo 'PLUGINS=()'
      echo ""
      echo '# Run bee new <plugins> to print all required variables'
      echo '# e.g. bee new git utils version'
    } > .beerc

    echo "created ${PWD}/.beerc"
  fi
}

new_plugin() {
  source_plugins "$@"
  local template=""
  for spec in $(resolve_plugin_specs "$@"); do
    source "${spec}"
    local new_func="${BEE_PLUGIN_NAME}::_new"
    unload_plugin_spec
    if [[ $(command -v "${new_func}") == "${new_func}" ]]; then
      template+="$("${new_func}")\n\n"
    fi
  done
  if [[ -n "${template}" ]]; then
    echo -e "${template}"
    command -v pbcopy &> /dev/null && {
      echo -e "${template}" | pbcopy
      echo "(template has been copied to clipboard, please paste into your .beerc)"
    }
  fi
}

bee_help_new=(
  "new | create new .beerc"
  "new <plugins> | show code templates for plugins"
)
new() {
  if (( $# == 0 )); then
    new_bee
  else
    new_plugin "$@"
  fi
}

bee_help_commands=(
  "commands | list all commands of enabled plugins"
  "commands <search> | list search result of enabled plugins"
)
commands() {
  compgen -A function \
    | grep --color=never '^[a-zA-Z]*::[a-zA-Z]' \
    | grep --color=never -- "$*" \
    || true
}

bee_help_changelog=(
  "changelog | show bee changelog"
  "changelog <plugin> | show changelog for plugin"
)
changelog() {
  if (( $# == 1 )); then
    for spec in $(resolve_plugin_specs "$1"); do
      source "${spec}"
      local log="${BEE_PLUGINS_HOME}/${BEE_PLUGIN_NAME}/${BEE_PLUGIN_VERSION}/CHANGELOG.md"
      unload_plugin_spec
      if [[ -f "${log}" ]]; then
        less "${log}"
      else
        echo "Changelog for $1 doesn't exit"
      fi
    done
  else
    less "${BEE_SYSTEM_HOME}/CHANGELOG.md"
  fi
}

bee_help_uninstall=("uninstall | uninstall bee from your system")
uninstall() {
  if [[ ${BEE_SILENT} == false ]]; then
    echo "You're about to uninstall bee from your system."
    echo "Do you want to continue? (yes | no)"
    read a
    if [[ "${a}" == "yes" ]]; then
      rm -f /usr/local/bin/bee
      rm -f /usr/local/etc/bash_completion.d/bee-completion.bash
      rm -rf /usr/local/opt/bee/
      rm -rf "${HOME}/.bee/caches"
      echo "Uninstalled bee"
      echo "Thanks for using bee"
    fi
  else
    rm -f /usr/local/bin/bee
    rm -f /usr/local/etc/bash_completion.d/bee-completion.bash
    rm -rf /usr/local/opt/bee/
    rm -rf "${HOME}/.bee/caches"
  fi
}

################################################################################
# help
################################################################################

help_bee() {
  local commands=""
  for help_var in $(compgen -v bee_help_); do
    help_var+="[@]"
    for entry in "${!help_var}"; do
      commands+="  ${entry}\n"
    done
  done

  local local_version="$(cat "${BEE_HOME}/version.txt")"
  echo "🐝 bee ${local_version} - plugin-based bash automation"
  echo ""
  echo "usage: bee [-s(ilent) -v(erbose)] <command> [<args>]"
  echo ""
  echo -e "${commands}" | column -s '|' -t
  echo ""
  echo "EXAMPLE"
  echo "  bee slack::message"
  echo "  bee version::bump_minor"
  echo "  bee ios::upload"
}

help_plugin() {
  for spec in $(resolve_plugin_specs "$1"); do
    source "${spec}"
    local readme="${BEE_PLUGINS_HOME}/${BEE_PLUGIN_NAME}/${BEE_PLUGIN_VERSION}/README.md"
    unload_plugin_spec
    if [[ -f "${readme}" ]]; then
      less "${readme}"
    else
      echo "Help for $1 doesn't exit"
    fi
  done
}

bee_help_help=(
  "help | show bee usage"
  "help <plugin> | show help for plugin"
)
help() {
  if (( $# == 1 )); then
    help_plugin "$@"
  else
    help_bee
  fi
}

# ################################################################################
# # main
# ################################################################################

BEE_INT_TRAPS=()
BEE_TERM_TRAPS=()
BEE_EXIT_TRAPS=()
BEE_CANCELED=false
BEE_MODE_INTERNAL=0
BEE_MODE_COMMAND=1
BEE_MODE=${BEE_MODE_INTERNAL}
T=${SECONDS}

bee_int() {
  BEE_CANCELED=true
  for t in "${BEE_INT_TRAPS[@]}"; do
    "$t"
  done
}

bee_term() {
  BEE_CANCELED=true
  for t in "${BEE_TERM_TRAPS[@]}"; do
    "$t"
  done
}

bee_exit() {
  local exit_code=$?
  for t in "${BEE_EXIT_TRAPS[@]}"; do
    "$t"
  done
  if [[ ${BEE_SILENT} == false ]] && (( ${BEE_MODE} == ${BEE_MODE_COMMAND} )); then
    if (( ${exit_code} == 0 )) && [[ ${BEE_CANCELED} == false ]]; then
      log "bzzzz ($(( ${SECONDS} - ${T} )) seconds)"
    else
      log "❌ bzzzz ($(( ${SECONDS} - ${T} )) seconds)"
    fi
  fi
}

main() {
  trap bee_int INT
  trap bee_term TERM
  trap bee_exit EXIT

  if [[ -v PLUGINS ]]; then
    source_plugins "${PLUGINS[@]}"
  fi

  while getopts ":sv" arg; do
    case $arg in
      s) BEE_SILENT=true ;;
      v) set -x ;;
      *)
        echo "Invalid option -${OPTARG}"
        exit 1
        ;;
    esac
  done

  shift $(( OPTIND - 1 ))

  if (( $# > 0 )); then
    local cmd=("$@")
    if [[ $(command -v "${cmd}") != *"${cmd}" ]]; then
      # command not found
      # try loading as a plugin
      source_plugins "${cmd}"
      shift
    fi

    if [[ "$*" == *"::"* ]]; then
      BEE_MODE=${BEE_MODE_COMMAND}
    else
      BEE_MODE=${BEE_MODE_INTERNAL}
    fi

    "$@"
  else
    help
  fi
}

main "$@"
