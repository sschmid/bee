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

resolve_plugins() {
  local found_all=true
  for plugin in "$@"; do
    local plugin_name="${plugin%:*}"
    local plugin_version="${plugin##*:}"
    local found=false
    if [[ "${plugin_name}" == "${plugin_version}" ]]; then
      # find latest
      for path in "${BEE_PLUGINS[@]}"; do
        local plugin_path="${path}/${plugin_name}"
        if [[ -d "${plugin_path}" ]]; then
          local versions=("${plugin_path}"/*/)
          plugin_version="$(basename -a "${versions[@]}" | sort -V | tail -n 1)"
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
      log_warn "Could not find plugin ${plugin}"
    fi
  done

  if [[ ${found_all} == false ]]; then
    exit 1
  fi
}

resolve_plugin_ids() {
  for plugin in $(resolve_plugins $@); do
    local plugin_id="${plugin%:*}"
    local plugin_name="${plugin_id%:*}"
    local plugin_version="${plugin_id##*:}"

    echo "${plugin_name}:${plugin_version}"
  done
}

# TODO: remove when expired (Dec 2020)
bee_migration_0390() {
  if [[ "$2" == "README.md" ]]; then
    log_warn "$1 doesn't support plugin versions yet, please consider updating the plugin"
    echo "."
  else
    echo "$2"
  fi
}

source_plugins() {
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
    git pull
    log "bee is up-to-date and ready to bzzzz"
  popd > /dev/null
}

bee_help_version=("version | show the current bee version")
version() {
  local remote_version="$(curl -fsL https://raw.githubusercontent.com/sschmid/bee/master/version.txt)"
  local local_version="$(cat "${BEE_HOME}/version.txt")"
  echo "bee ${local_version}"
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
  for plugin in $(resolve_plugins "$@"); do
    local plugin_id="${plugin%:*}"
    local plugin_name="${plugin_id%:*}"

    local new_func="${plugin_name}::_new"
    if [[ $(command -v "${new_func}") == "${new_func}" ]]; then
      template+="$("${plugin_name}::_new")\n\n"
    fi
  done
  echo -e "${template}"
  command -v pbcopy &> /dev/null && {
    echo -e "${template}" | pbcopy
    echo "(template has been copied to clipboard, please paste into your .beerc)"
  }
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
  "commands <names> | list all commands of enabled and specified plugins"
)
commands() {
  if (( $# == 0 )); then
    compgen -A function | grep --color=never '^[a-zA-Z]*::[a-zA-Z]' || true
  else
    for command in "$@"; do
      compgen -A function "${command}" | grep --color=never '^[a-zA-Z]*::[a-zA-Z]' || true
    done
  fi
}

bee_help_plugins=("plugins | list all plugins")
plugins() {
  for path in "${BEE_PLUGINS[@]}"; do
    for plugin in "${path}"/*/; do
      basename "${plugin}"
    done
  done
}

bee_help_deps=("deps | list dependencies of enabled plugins")
deps() {
  missing=()
  local plugin_ids="$(resolve_plugin_ids "${PLUGINS[@]}")"
  for plugin_id in ${plugin_ids}; do
    local plugin_name="${plugin_id%:*}"
    local deps_func="${plugin_name}::_deps"
    if [[ $(command -v "${deps_func}") == "${deps_func}" ]]; then
      local dependencies=($(${deps_func} | tr ' ' '\n'))
      local status=""
      for dep in "${dependencies[@]}"; do
        local found_dep=false
        for p in ${plugin_ids}; do
          if [[ "${p}" == "${dep}" ]] || [[ "${p%:*}" == "${dep}" ]]; then
            found_dep=true
            break
          fi
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
  for plugin in $(resolve_plugins "$@"); do
    local plugin_id="${plugin%:*}"
    local plugin_name="${plugin_id%:*}"
    local plugin_version="${plugin_id##*:}"
    local plugin_path="${plugin##*:}"

    local resources_dir="${plugin_path}/${plugin_version}/resources"
    if [[ -d "${resources_dir}" ]]; then
      local target_dir="${BEE_RESOURCES}/${plugin_name}"
      echo "Copying resources into ${target_dir}"
      mkdir -p "${target_dir}"
      cp -r "${resources_dir}/". "${target_dir}/"
    fi
  done
}

bee_help_changelog=(
  "changelog | show bee changelog"
  "changelog <plugin> | show changelog for plugin"
)
changelog() {
  if (( $# == 1 )); then
    local plugin=$(resolve_plugins $1)
    local plugin_path="${plugin##*:}"
    local log="${plugin_path}/CHANGELOG.md"
    if [[ -f "${log}" ]]; then
      less "${log}"
    else
      echo "Changelog for $1 doesn't exit"
    fi
  else
    less "${BEE_SYSTEM_HOME}/CHANGELOG.md"
  fi
}

bee_help_uninstall=("uninstall | uninstall bee from your system")
uninstall() {
  rm -f /usr/local/bin/bee
  rm -f /usr/local/etc/bash_completion.d/bee-completion.bash
  rm -rf /usr/local/opt/bee/
  rm -rf "${HOME}/.bee/versions"
  echo "Uninstalled bee"
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
  local plugin=$(resolve_plugins $1)
  local plugin_id="${plugin%:*}"
  local plugin_version="${plugin_id##*:}"
  local plugin_path="${plugin##*:}"

  local readme="${plugin_path}/${plugin_version}/README.md"
  if [[ -f "${readme}" ]]; then
    less "${readme}"
  else
    echo "Help for $1 doesn't exit"
  fi
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
# # job
# ################################################################################

BEE_SPINNER_FRAMES=(
  '🐝'
  ' 🐝'
  '  🐝'
  '   🐝'
  '    🐝'
  '     🐝'
  '      🐝'
  '       🐝'
  '        🐝'
  '         🐝'
  '        🐝'
  '       🐝'
  '      🐝'
  '     🐝'
  '    🐝'
  '   🐝'
  '  🐝'
  ' 🐝'
  '🐝'
)
BEE_SPINNER_INTERVAL=0.1

BEE_SPINNER_PID=0
BEE_JOB_RUNNING=false
BEE_JOB_TITLE=""
BEE_JOB_LOGFILE=""

bee_spinner() {
  while true; do
    for i in "${BEE_SPINNER_FRAMES[@]}"; do
      echo -ne "\r\033[2K${BEE_JOB_TITLE} ${i}"
      sleep ${BEE_SPINNER_INTERVAL}
    done
  done
}

start_spinner() {
  tput civis
  stty -echo
  bee_spinner &
  BEE_SPINNER_PID=$!
}

stop_spinner() {
  if (( ${BEE_SPINNER_PID} != 0 )); then
    kill ${BEE_SPINNER_PID} || true
    BEE_SPINNER_PID=0
  fi
  if [[ -t 1 ]]; then
    stty echo
    tput cnorm
  fi
}

complete_job() {
  stop_spinner
  echo -e "\r\033[2K\033[0;32m${BEE_JOB_TITLE} ✔︎\033[0m"
}

bee_help_job=("job <title> <command> | run a command as a job")
job() {
  BEE_JOB_RUNNING=true
  BEE_JOB_TITLE="$1"
  shift
  start_spinner
  BEE_JOB_LOGFILE="${BEE_RESOURCES}/logs/$(date -u '+%Y-%m-%d-%H-%M-%S')-job-${BEE_JOB_TITLE}-$(uuidgen).log"
  mkdir -p "${BEE_RESOURCES}/logs"
  "$@" &> "${BEE_JOB_LOGFILE}"
  complete_job
  BEE_JOB_RUNNING=false
}

job_int() {
  stop_spinner
  echo "Aborted by $(whoami)" >> "${BEE_JOB_LOGFILE}"
}

job_term() {
  stop_spinner
  echo "Terminated" >> "${BEE_JOB_LOGFILE}"
}

job_exit() {
  local exit_code=$1
  if (( ${exit_code} != 0 )); then
    stop_spinner
    echo -e "\r\033[2K\033[0;31m${BEE_JOB_TITLE} ✗\033[0m"
  fi
}

# ################################################################################
# # main
# ################################################################################

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
