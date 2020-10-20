#!/usr/bin/env bash
#
# 🐝 bee - plugin-based bash automation
#
# Shell Style Guide
# https://google.github.io/styleguide/shell.xml
set -eu

# init #########################################################################

resolve_home() {
  local current_dir="${PWD}"
  local path="${1}"
  while [[ -L ${path} ]]; do
    local link="$(readlink "${path}")"
    cd "$(dirname "${path}")"
    cd "$(dirname "${link}")"
    path="${link}"
  done
  cd "${current_dir}"
  echo "$(dirname "$(dirname "${path}")")"
}

export BEE_HOME="$(resolve_home "${BASH_SOURCE[0]}")"

# help #########################################################################

help_bee() {
  local commands=""
  for command in $(internal_commands); do
    local help_var="${command}_internal_help[@]"
    for entry in "${!help_var}"; do
      commands+="  ${entry}\n"
    done
  done

  local local_version="$(cat "${BEE_HOME}/version.txt")"
  echo "🐝 bee ${local_version} - plugin-based bash automation"
  echo ""
  echo "usage: bee [--silent --verbose] <command> [<args>]"
  echo ""
  echo -e "${commands}" | column -s '|' -t
  echo ""
  echo "customization:"
  echo "  see ~/.beerc"
  echo ""
  echo "EXAMPLE"
  echo "  bee slack::message"
  echo "  bee version::bump_minor"
  echo "  bee ios::upload"
}

help_plugin() {
  local found_help=false
  for dir in "${BEE_PLUGINS[@]}"; do
    local readme="${dir}/${1}/README.md"
    if [[ -f "${readme}" ]]; then
      found_help=true
      less "${readme}"
      break
    fi
  done
  if [[ ${found_help} == false ]]; then
    echo "Help for ${1} doesn't exit"
  fi
}

help_internal_help=("help | show bee usage" "help <plugin> | show help for plugin")
help() {
  if (( $# == 1 )); then
    help_plugin "$@"
  else
    help_bee
  fi
}

################################################################################
# commands
################################################################################

update_internal_help=("update | update bee to latest version")
update() {
  pushd "${BEE_HOME}" > /dev/null
    git pull
    echo "bee is up-to-date and ready to bzzzz"
  popd > /dev/null
}

version_internal_help=("version | show bee version")
version() {
  local remote_version="$(curl -fsL https://raw.githubusercontent.com/sschmid/bee/master/version.txt)"
  local local_version="$(cat "${BEE_HOME}/version.txt")"
  if [[ -n "${remote_version}" ]]; then
    echo "bee ${local_version} (latest version: ${remote_version})"
  else
    echo "bee ${local_version}"
  fi
}

wiki_internal_help=("wiki | open wiki")
wiki() {
  open "https://github.com/sschmid/bee/wiki"
}

donate_internal_help=("donate | bee is free, but powered by your donations")
donate() {
  open "https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=M7WHTWP4GE75Y"
}

plugins_internal_help=("plugins | list all plugins")
plugins() {
  for dir in "${BEE_PLUGINS[@]}"; do
    for path in "${dir}"/*; do
      if [[ -d "${path}" ]]; then
        basename "${path}"
      fi
    done
  done
}

commands_internal_help=("commands | list all commands of enabled plugins")
commands() {
  compgen -A function | grep --color=never '^[_a-zA-Z]*::[a-zA-Z]'
}

new_bee() {
  if [[ -f bee.sh ]]; then
    echo "bee.sh already exists"
    exit 1
  fi
  echo '#!/usr/bin/env bash' > bee.sh
  echo "PROJECT=\"$(basename ${PWD})\"" >> bee.sh
  echo 'PLUGINS=()
RESOURCES=.bee

# Run bee new <plugins> to print all required variables
# e.g. bee new git utils version' >> bee.sh

  echo "created ${PWD}/bee.sh"
}

new_plugin() {
  source_plugins "$@"
  local template=""
  for plugin_name in "$@"; do
    template+="$("${plugin_name}::_new")\n\n"
  done
  echo -e "${template}"
  command -v pbcopy &> /dev/null && {
    echo -e "${template}" | pbcopy
    echo "(template has been copied to clipboard)"
  }
}

new_internal_help=(
  "new | create new bee.sh"
  "new <plugins> | show code templates for plugins"
)
new() {
  if (( $# == 0 )); then
    new_bee
  else
    new_plugin "$@"
  fi
}

deps_internal_help=("deps | list dependencies of enabled plugins")
deps() {
  missing=()
  for plugin_name in "${PLUGINS[@]}"; do
    local func="${plugin_name}::_deps"

    if [[ $(command -v "${func}") == "${func}" ]]; then
      local deps=$(${func})
      local result=""

      for dep in ${deps}; do
        local found_dep=false
        for p in "${PLUGINS[@]}"; do
          if [[ "${p}" == "${dep}" ]]; then
            found_dep=true
            break
          fi
        done

        if [[ ${found_dep} == true ]]; then
          result+=" \033[32m${dep}\033[0m"
        else
          result+=" \033[31m${dep}\033[0m"
          missing+=("${dep}")
        fi
      done

      echo -e "${plugin_name} =>${result}"
    fi
  done

  if [[ ${#missing[@]} -gt 0 ]]; then
    echo ""
    echo "Missing dependencies:"
    echo "${missing[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' '
  fi
}

res_internal_help=("res <plugins> | copy template files into resources dir")
res() {
  for plugin_name in "$@"; do
    for dir in "${BEE_PLUGINS[@]}"; do
      local template_dir="${dir}/${plugin_name}/templates"
      if [[ -d "${template_dir}" ]]; then
        local target_dir="${RESOURCES}/${plugin_name}"
        echo "Copying resources into ${target_dir}"
        mkdir -p "${target_dir}/"
        cp -r "${template_dir}/". "${target_dir}/"
      fi
    done
  done
}

uninstall_internal_help=("uninstall | uninstall bee from your system")
uninstall() {
  rm -f /usr/local/bin/bee
  rm -f /usr/local/etc/bash_completion.d/bee-completion.bash
  rm -rf /usr/local/opt/bee/
  log "Uninstalled bee"
}

################################################################################
# run
################################################################################

BEE_SILENT=false
BEE_CANCELED=false
BEE_MODE_INTERNAL=0
BEE_MODE_COMMAND=1
BEE_MODE=${BEE_MODE_INTERNAL}
T=${SECONDS}

cancel() {
  BEE_CANCELED=true
}

terminate() {
  local exit_code=$?
  if [[ ${BEE_SILENT} == false ]]; then
    if (( ${BEE_MODE} == ${BEE_MODE_COMMAND} )); then
      if (( ${exit_code} == 0 )) && [[ ${BEE_CANCELED} == false ]]; then
        log "bzzzz ($((${SECONDS} - ${T})) seconds)"
      else
        log "❌ bzzzz ($((${SECONDS} - ${T})) seconds)"
      fi
    fi
  fi
}


main() {
  trap cancel INT
  trap cancel TERM
  trap terminate EXIT

  source "${BEE_HOME}/src/bee_log.sh"
  source "${BEE_HOME}/src/bee_utils.sh"
  source_config "${BEE_RC:-${HOME}/.beerc}"

  if [[ -f bee.sh ]]; then
    source bee.sh
    source_plugins "${PLUGINS[@]}"
  fi

  if (( $# > 0 )); then
    if [[ "${1}" == "--verbose" ]]; then
      shift
      set -x
    fi
    if [[ "${1}" == "--silent" ]]; then
      shift
      BEE_SILENT=true
    fi

    local cmd=("$@")

    if [[ $(command -v "${cmd}") != "${cmd}" ]]; then
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
