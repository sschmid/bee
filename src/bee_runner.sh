#!/usr/bin/env bash

################################################################################
# commands
################################################################################

builtin_commands() {
  local commands=""
  for command in $(compgen -A function); do
    help_var="${command}_builtin_help[@]"
    if [[ -v "${help_var}" ]]; then
      commands+="${command}\n"
    fi
  done

  echo -e "${commands}"
}

update_builtin_help=("update | update bee to latest version")
update() {
  pushd "${BEE_SYSTEM_HOME}" > /dev/null
    git pull
    echo "bee is up-to-date and ready to bzzzz"
  popd > /dev/null
}

version_builtin_help=("version | show bee version")
version() {
  local remote_version="$(curl -fsL https://raw.githubusercontent.com/sschmid/bee/master/version.txt)"
  local local_version="$(cat "${BEE_HOME}/version.txt")"
  if [[ -n "${remote_version}" ]]; then
    echo "bee ${local_version} (latest version: ${remote_version})"
  else
    echo "bee ${local_version}"
  fi
}

wiki_builtin_help=("wiki | open wiki")
wiki() {
  open "https://github.com/sschmid/bee/wiki"
}

donate_builtin_help=("donate | bee is free, but powered by your donations")
donate() {
  open "https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=M7WHTWP4GE75Y"
}

plugins_builtin_help=("plugins | list all plugins")
plugins() {
  for path in "${BEE_PLUGINS[@]}"; do
    for plugin in "${path}"/*; do
      if [[ -d "${plugin}" ]]; then
        basename "${plugin}"
      fi
    done
  done
}

commands_builtin_help=("commands | list all commands of enabled plugins")
commands() {
  compgen -A function | grep --color=never '^[a-zA-Z]*::[a-zA-Z]' || true
}

new_bee() {
  if [[ -f .beerc ]]; then
    echo ".beerc already exists"
    exit 1
  fi
  local local_version="$(cat "${BEE_HOME}/version.txt")"
  {
    echo '#!/usr/bin/env bash'
    echo "BEE_PROJECT=\"$(basename ${PWD})\""
    echo "BEE_VERSION=${local_version}"
    echo 'PLUGINS=()'
    echo ""
    echo "# Run bee new <plugins> to print all required variables"
    echo "# e.g. bee new git utils version"
  } > .beerc

  echo "created ${PWD}/.beerc"
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

new_builtin_help=(
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

deps_builtin_help=("deps | list dependencies of enabled plugins")
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
    echo ""
  fi
}

res_builtin_help=("res <plugins> | copy template files into resources dir")
res() {
  for plugin_name in "$@"; do
    for path in "${BEE_PLUGINS[@]}"; do
      local template_dir="${path}/${plugin_name}/templates"
      if [[ -d "${template_dir}" ]]; then
        local target_dir="${BEE_RESOURCES}/${plugin_name}"
        echo "Copying resources into ${target_dir}"
        mkdir -p "${target_dir}/"
        cp -r "${template_dir}/". "${target_dir}/"
      fi
    done
  done
}

uninstall_builtin_help=("uninstall | uninstall bee from your system")
uninstall() {
  rm -f /usr/local/bin/bee
  rm -f /usr/local/etc/bash_completion.d/bee-completion.bash
  rm -rf /usr/local/opt/bee/
  rm -rf "${HOME}/.bee/versions"
  log "Uninstalled bee"
}

# help #########################################################################

help_bee() {
  local commands=""
  for command in $(builtin_commands); do
    local help_var="${command}_builtin_help[@]"
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
  echo "EXAMPLE"
  echo "  bee slack::message"
  echo "  bee version::bump_minor"
  echo "  bee ios::upload"
}

help_plugin() {
  local found_help=false
  for path in "${BEE_PLUGINS[@]}"; do
    local readme="${path}/${1}/README.md"
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

help_builtin_help=("help | show bee usage" "help <plugin> | show help for plugin")
help() {
  if (( $# == 1 )); then
    help_plugin "$@"
  else
    help_bee
  fi
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

bee_int() {
  BEE_CANCELED=true
  if [[ ${BEE_JOB_RUNNING} == true ]]; then
    job_int
  fi
}

bee_term() {
  BEE_CANCELED=true
  if [[ ${BEE_JOB_RUNNING} == true ]]; then
    job_term
  fi
}

bee_exit() {
  local exit_code=$?
  if [[ ${BEE_JOB_RUNNING} == true ]]; then
    job_exit "${exit_code}"
  fi
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

bee_run() {
  trap bee_int INT
  trap bee_term TERM
  trap bee_exit EXIT

  source "${BEE_HOME}/src/bee_log.sh"
  source "${BEE_HOME}/src/bee_utils.sh"
  source "${BEE_HOME}/src/bee_job.sh"

  if [[ -v PLUGINS ]]; then
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
