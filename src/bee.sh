#!/usr/bin/env bash

# ################################################################################
# # utils
# ################################################################################

assert_file() {
  local file="${!1}"
  if [[ ! -f "${file}" ]]; then
    echo "🔴 ASSERT $1: file not found: ${file}" >&2
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
# job
################################################################################

BEE_SPINNER_FRAMES=('🐝' ' 🐝' '  🐝' '   🐝' '    🐝' '     🐝' '      🐝' '       🐝' '        🐝' '         🐝' '        🐝' '       🐝' '      🐝' '     🐝' '    🐝' '   🐝' '  🐝' ' 🐝' '🐝')
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
  if (( BEE_SPINNER_PID != 0 )); then
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

  if [[ -v BEE_PROJECT ]]; then
    mkdir -p "${BEE_RESOURCES}/logs"
    BEE_JOB_LOGFILE="${BEE_RESOURCES}/logs/$(date -u '+%Y-%m-%d-%H-%M-%S')-job-${BEE_JOB_TITLE}-$(uuidgen).log"
  else
    BEE_JOB_LOGFILE=/dev/null
  fi

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
  if (( exit_code != 0 )); then
    stop_spinner
    echo -e "\r\033[2K\033[0;31m${BEE_JOB_TITLE} ✗\033[0m"
  fi
}

################################################################################
# registries
################################################################################

BEE_REGISTRIES_HOME="${HOME}/.bee/caches/registries"
BEE_PLUGINS_HOME="${HOME}/.bee/caches/plugins"
BEE_LINT_HOME="${HOME}/.bee/caches/lint"

declare -A LOCAL_REGISTRY_PATH_CACHE=()
LOCAL_REGISTRY_PATH_RESULT=""
build_local_registry_path() {
  local url="$1"
  LOCAL_REGISTRY_PATH_RESULT=""
  if [[ ! -v LOCAL_REGISTRY_PATH_CACHE["${url}"] ]]; then
    if [[ "${url}" =~ ^git@.* ]]; then
      LOCAL_REGISTRY_PATH_RESULT="$(dirname "${url#git@}")/$(basename "${url}" .git)"
      LOCAL_REGISTRY_PATH_CACHE["${url}"]="${LOCAL_REGISTRY_PATH_RESULT}"
    elif [[ "${url}" =~ ^file:// ]]; then
      LOCAL_REGISTRY_PATH_RESULT="$(basename "${url}")"
      LOCAL_REGISTRY_PATH_CACHE["${url}"]="${LOCAL_REGISTRY_PATH_RESULT}"
    else
      log_warn "Unsupported registry url: ${url}"
    fi
  else
    LOCAL_REGISTRY_PATH_RESULT="${LOCAL_REGISTRY_PATH_CACHE["${url}"]}"
  fi
}

BEE_REGISTRY_CACHES_RESULT=()
resolve_registry_caches() {
  BEE_REGISTRY_CACHES_RESULT=()
  for url in "$@"; do
    build_local_registry_path "${url}"
    if [[ -n "${LOCAL_REGISTRY_PATH_RESULT}" ]]; then
      BEE_REGISTRY_CACHES_RESULT+=("${BEE_REGISTRIES_HOME}/${LOCAL_REGISTRY_PATH_RESULT}")
    fi
  done
}

BEE_LINT_CACHE_RESULT=""
resolve_lint_cache() {
  BEE_LINT_CACHE_RESULT=""
  build_local_registry_path "$1"
  if [[ -n "${LOCAL_REGISTRY_PATH_RESULT}" ]]; then
    BEE_LINT_CACHE_RESULT="${BEE_LINT_HOME}/${LOCAL_REGISTRY_PATH_RESULT}"
  fi
}

bee_help_pull=(
  "pull | update all plugin registries"
  "pull <urls> | update plugin registries"
)
pull() {
  log "Pulling registries"
  for url in "${@:-"${BEE_PLUGIN_REGISTRIES[@]}"}"; do
    resolve_registry_caches "${url}"
    if [[ -n "${BEE_REGISTRY_CACHES_RESULT}" ]]; then
      if [[ -d "${BEE_REGISTRY_CACHES_RESULT}" ]]; then
        pushd "${BEE_REGISTRY_CACHES_RESULT}" > /dev/null
          git pull -q &
        popd > /dev/null
      else
        git clone -q "${url}" "${BEE_REGISTRY_CACHES_RESULT}" &
      fi
    fi
  done
  wait
}

################################################################################
# plugins
################################################################################

declare -A BEE_PLUGIN_SPECS_CACHE=()
BEE_PLUGIN_SPECS_RESULT=()
resolve_plugin_specs() {
  BEE_PLUGIN_SPECS_RESULT=()
  resolve_registry_caches "${BEE_PLUGIN_REGISTRIES[@]}"
  for plugin in "$@"; do
    if [[ ! -v BEE_PLUGIN_SPECS_CACHE["${plugin}"] || "${BEE_PLUGIN_SPECS_CACHE["${plugin}"]}" == false ]]; then
      local plugin_name="${plugin%:*}"
      local plugin_version="${plugin##*:}"
      local found=false
      if [[ "${plugin_name}" == "${plugin_version}" ]]; then
        # find latest
        for cache in "${BEE_REGISTRY_CACHES_RESULT[@]}"; do
          local plugin_path="${cache}/${plugin_name}"
          if [[ -d "${plugin_path}" ]]; then
            local versions=("${plugin_path}"/*/)
            if [[ -d "${versions}" ]]; then
              plugin_version="$(basename -a "${versions[@]}" | sort -V | tail -n 1)"
              plugin_path="${plugin_path}/${plugin_version}/plugin.sh"
              if [[ -f "${plugin_path}" ]]; then
                found=true
                BEE_PLUGIN_SPECS_RESULT+=("${plugin_path}")
                BEE_PLUGIN_SPECS_CACHE["${plugin}"]="${plugin_path}"
                BEE_PLUGIN_SPECS_CACHE["${plugin_name}:${plugin_version}"]="${plugin_path}"
                break
              fi
            fi
          fi
        done
      else
        for cache in "${BEE_REGISTRY_CACHES_RESULT[@]}"; do
          local plugin_path="${cache}/${plugin_name}/${plugin_version}/plugin.sh"
          if [[ -f "${plugin_path}" ]]; then
            found=true
            BEE_PLUGIN_SPECS_RESULT+=("${plugin_path}")
            BEE_PLUGIN_SPECS_CACHE["${plugin}"]="${plugin_path}"
            break
          fi
        done
      fi

      if [[ "${found}" == false ]]; then
        if [[ ! -v BEE_PLUGIN_SPECS_CACHE["${plugin}"] ]]; then
          log_warn "Could not find plugin ${plugin}"
        fi
        BEE_PLUGIN_SPECS_CACHE["${plugin}"]=false
      fi
    elif [[ "${BEE_PLUGIN_SPECS_CACHE["${plugin}"]}" != false ]]; then
      BEE_PLUGIN_SPECS_RESULT+=("${BEE_PLUGIN_SPECS_CACHE["${plugin}"]}")
    fi
  done
}

unload_plugin_spec() {
  unset BEE_PLUGIN_NAME
  unset BEE_PLUGIN_VERSION
  unset BEE_PLUGIN_LICENSE
  unset BEE_PLUGIN_HOMEPAGE
  unset BEE_PLUGIN_AUTHORS
  unset BEE_PLUGIN_INFO
  unset BEE_PLUGIN_SOURCE
  unset BEE_PLUGIN_TAG
  unset BEE_PLUGIN_DEPENDENCIES
}

lint_var() {
  if [[ ! -v ${1} || -z "${!1}" ]]; then
    echo -e "\033[31m${1} is required\033[0m"
  else
    echo -e "\033[32m${1} ✔︎\033[0m"
  fi
}

lint_var_value() {
  if [[ ! -v ${1} || -z "${!1}" ]]; then
    echo -e "\033[31m${1} is required\033[0m"
  else
    if [[ "${!1}" != "$2" ]]; then
      echo -e "\033[31m$1 is set to ${!1} but must be $2\033[0m"
    else
      echo -e "\033[32m${1} ${!1} ✔︎\033[0m"
    fi
  fi
}

bee_help_lint=("lint <spec> | validate plugin specification")
lint() {
  local spec="$1"
  source "${spec}"

  lint_var_value BEE_PLUGIN_NAME "$(basename "$(dirname "$(dirname "${spec}")")")"
  lint_var_value BEE_PLUGIN_VERSION "$(basename "$(dirname "${spec}")")"
  lint_var BEE_PLUGIN_LICENSE
  lint_var BEE_PLUGIN_HOMEPAGE
  lint_var BEE_PLUGIN_AUTHORS
  lint_var BEE_PLUGIN_INFO
  lint_var BEE_PLUGIN_SOURCE
  lint_var BEE_PLUGIN_TAG

  if [[ -v BEE_PLUGIN_DEPENDENCIES ]]; then
    echo -e "\033[32mBEE_PLUGIN_DEPENDENCIES ${BEE_PLUGIN_DEPENDENCIES[*]} ✔︎\033[0m"
  else
    echo -e "\033[32mBEE_PLUGIN_DEPENDENCIES no dependencies ✔︎\033[0m"
  fi

  if [[ -v BEE_PLUGIN_SOURCE && -v BEE_PLUGIN_TAG && -n "${BEE_PLUGIN_SOURCE}" && -n "${BEE_PLUGIN_TAG}" ]]; then
    resolve_lint_cache "${BEE_PLUGIN_SOURCE}"
    if [[ -n "${BEE_LINT_CACHE_RESULT}" ]]; then
      if [[ -d "${BEE_LINT_CACHE_RESULT}" ]]; then
        pushd "${BEE_LINT_CACHE_RESULT}" > /dev/null
          job "BEE_PLUGIN_SOURCE" git fetch || true
        popd > /dev/null
      else
        job "BEE_PLUGIN_SOURCE" git clone "${BEE_PLUGIN_SOURCE}" "${cache}" || true
      fi
      if [[ -d "${BEE_LINT_CACHE_RESULT}" ]]; then
        pushd "${BEE_LINT_CACHE_RESULT}" > /dev/null
          if ! git show-ref -q --tags --verify -- "refs/tags/${BEE_PLUGIN_TAG}"; then
            echo -e "\033[31mBEE_PLUGIN_TAG is set to ${BEE_PLUGIN_TAG} but doesn't exist in ${BEE_PLUGIN_SOURCE}\033[0m"
          else
            echo -e "\033[32mBEE_PLUGIN_TAG ${BEE_PLUGIN_TAG} ✔︎\033[0m"
          fi
        popd > /dev/null
      else
        echo -e "\033[31mBEE_PLUGIN_TAG (BEE_PLUGIN_SOURCE failed)\033[0m"
      fi
    else
      echo -e "\033[31mBEE_PLUGIN_SOURCE ${BEE_PLUGIN_SOURCE}\033[0m"
      echo -e "\033[31mBEE_PLUGIN_TAG (BEE_PLUGIN_SOURCE failed)\033[0m"
    fi
  fi

  unload_plugin_spec
}

bee_help_info=("info | show plugin spec info")
info() {
  resolve_plugin_specs "$1"
  for spec in "${BEE_PLUGIN_SPECS_RESULT[@]}"; do
    source "${spec}"
    echo "name: | ${BEE_PLUGIN_NAME}
version: | ${BEE_PLUGIN_VERSION}
license: | ${BEE_PLUGIN_LICENSE}
homepage: | ${BEE_PLUGIN_HOMEPAGE}
authors: | ${BEE_PLUGIN_AUTHORS}
summary: | ${BEE_PLUGIN_INFO}
source: | ${BEE_PLUGIN_SOURCE}
tag: | ${BEE_PLUGIN_TAG}
dependencies: | ${BEE_PLUGIN_DEPENDENCIES[@]:-"none"}" | column -s '|' -t
    unload_plugin_spec
  done
}

bee_help_deps=(
  "deps | list dependencies of enabled plugins"
  "deps <plugins> | list dependencies of plugins"
)
declare -A deps_cache=()
DEPS_RESULT=()
deps() {
  DEPS_RESULT=()
  deps_cache=()
  deps_recursive ${@:-"${PLUGINS[@]}"}
  if [[ "${#DEPS_RESULT[@]}" -gt 0 ]]; then
    DEPS_RESULT=($(echo "${DEPS_RESULT[*]}" | sort -u))
  fi
}

deps_recursive() {
  resolve_plugin_specs "$@"
  local specs=("${BEE_PLUGIN_SPECS_RESULT[@]}")
  for spec in "${specs[@]}"; do
    if [[ ! -v deps_cache["${spec}"] ]]; then
      deps_cache["${spec}"]=true
      source "${spec}"
      if [[ -v BEE_PLUGIN_DEPENDENCIES ]]; then
        local dependencies=("${BEE_PLUGIN_DEPENDENCIES[@]}")
        unload_plugin_spec
        DEPS_RESULT+=("${dependencies[@]}")
        deps_recursive "${dependencies[@]}"
      else
        unload_plugin_spec
      fi
    fi
  done
}

bee_help_depstree=(
  "depstree | list dependencies hierarchy of enabled plugins"
  "depstree <plugins> | list dependencies hierarchy of plugins"
)
declare -A depstree_cache=()
depstree_indent=""
depstree() {
  resolve_plugin_specs ${@:-"${PLUGINS[@]}"}
  local specs=("${BEE_PLUGIN_SPECS_RESULT[@]}")
  for spec in "${specs[@]}"; do
    source "${spec}"
    echo "${depstree_indent}${BEE_PLUGIN_NAME}:${BEE_PLUGIN_VERSION}"
    if [[ ! -v depstree_cache["${spec}"] ]]; then
      depstree_cache["${spec}"]=true
      if [[ -v BEE_PLUGIN_DEPENDENCIES ]]; then
        depstree_indent="${depstree_indent/'├'/'|'}"
        depstree_indent="${depstree_indent//'─'/' '}├── "
        local dependencies=("${BEE_PLUGIN_DEPENDENCIES[@]}")
        unload_plugin_spec
        depstree "${dependencies[@]}"
        if [[ "${#depstree_indent}" -ge 8 ]]; then
          depstree_indent="${depstree_indent:0:-8}├── "
        else
          depstree_indent=""
        fi
      else
        unload_plugin_spec
      fi
    else
      unload_plugin_spec
    fi
  done
}

PLUGINS_WITH_DEPENDENCIES_RESULT=()
plugins_with_dependencies() {
  PLUGINS_WITH_DEPENDENCIES_RESULT=()
  resolve_plugin_specs "$@"
  for spec in "${BEE_PLUGIN_SPECS_RESULT[@]}"; do
    source "${spec}"
    PLUGINS_WITH_DEPENDENCIES_RESULT+=("${BEE_PLUGIN_NAME}:${BEE_PLUGIN_VERSION}")
    unload_plugin_spec
  done
  deps "${plugins[@]}"
  PLUGINS_WITH_DEPENDENCIES_RESULT+=("${DEPS_RESULT[@]}")
  if [[ ${#PLUGINS_WITH_DEPENDENCIES_RESULT[@]} -gt 0 ]]; then
    PLUGINS_WITH_DEPENDENCIES_RESULT=($(echo "${PLUGINS_WITH_DEPENDENCIES_RESULT[*]}" | sort -u))
  fi
}

bee_help_install=(
  "install | install all enabled plugins"
  "install <plugins> | install plugins"
)
declare -A install_cache=()
install() {
  pull || true
  plugins_with_dependencies ${@:-"${PLUGINS[@]}"}
  resolve_plugin_specs "${PLUGINS_WITH_DEPENDENCIES_RESULT[@]}"
  for spec in "${BEE_PLUGIN_SPECS_RESULT[@]}"; do
    if [[ ! -v install_cache["${spec}"] ]]; then
      install_cache["${spec}"]=true
      source "${spec}"
      local path="${BEE_PLUGINS_HOME}/${BEE_PLUGIN_NAME}/${BEE_PLUGIN_VERSION}"
      if [[ ! -d "${path}" ]]; then
        {
          git -c advice.detachedHead=false clone -q --depth 1 --branch "${BEE_PLUGIN_TAG}" "${BEE_PLUGIN_SOURCE}" "${path}"
          echo -e "\033[32m${BEE_PLUGIN_NAME}:${BEE_PLUGIN_VERSION} ✔︎\033[0m"
        } &
      else
        echo "${BEE_PLUGIN_NAME}:${BEE_PLUGIN_VERSION}"
      fi
      unload_plugin_spec
    fi
  done
  wait
}

source_plugins() {
  resolve_plugin_specs "$@"
  for spec in "${BEE_PLUGIN_SPECS_RESULT[@]}"; do
    source "${spec}"
    local path="${BEE_PLUGINS_HOME}/${BEE_PLUGIN_NAME}/${BEE_PLUGIN_VERSION}/${BEE_PLUGIN_NAME}.sh"
    local plugin="${BEE_PLUGIN_NAME}:${BEE_PLUGIN_VERSION}"
    unload_plugin_spec
    if [[ ! -f "${path}" ]]; then
      install "${plugin}"
    fi
    source "${path}"
  done
}

bee_help_plugins=("plugins [-a(ll) -v(ersion) -i(info)] | list all plugins")
plugins() {
  local show_all=false
  local show_version=false
  local show_info=false
  while getopts ":avi" arg; do
    case $arg in
      a) show_all=true ;;
      v) show_version=true ;;
      i) show_info=true ;;
      *)
        log_error "${FUNCNAME[0]} Invalid option -${OPTARG}"
        exit 1
        ;;
    esac
  done
  shift $(( OPTIND - 1 ))

  local list=""
  if [[ "${show_all}" == false ]]; then
    plugins_with_dependencies "${PLUGINS[@]}"
    resolve_plugin_specs "${PLUGINS_WITH_DEPENDENCIES_RESULT[@]}"
    for spec in "${BEE_PLUGIN_SPECS_RESULT[@]}"; do
      source "${spec}"
      list+="${BEE_PLUGIN_NAME}"
      if [[ "${show_version}" == true ]]; then
        list+=":${BEE_PLUGIN_VERSION}"
      fi
      if [[ "${show_info}" == true ]]; then
        list+=" | ${BEE_PLUGIN_INFO}"
      fi
      list+="\n"
      unload_plugin_spec
    done
  else
    resolve_registry_caches "${BEE_PLUGIN_REGISTRIES[@]}"
    for cache in "${BEE_REGISTRY_CACHES_RESULT[@]}"; do
      local plugins=("${cache}"/*/)
      if [[ -d "${plugins}" ]]; then
        plugins=($(basename -a "${plugins[@]}"))
        resolve_plugin_specs "${plugins[@]}"
        for spec in "${BEE_PLUGIN_SPECS_RESULT[@]}"; do
          source "${spec}"
          list+="${BEE_PLUGIN_NAME}"
          if [[ "${show_version}" == true ]]; then
            list+=":${BEE_PLUGIN_VERSION}"
          fi
          if [[ "${show_info}" == true ]]; then
            list+=" | ${BEE_PLUGIN_INFO}"
          fi
          list+="\n"
          unload_plugin_spec
        done
      fi
    done
  fi
  echo -ne "${list}" | column -s '|' -t
}

bee_help_res=("res <plugins> | copy plugin resources into resources dir")
res() {
  resolve_plugin_specs "$@"
  for spec in "${BEE_PLUGIN_SPECS_RESULT[@]}"; do
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
  local local_version
  local_version="$(cat "${BEE_HOME}/version.txt")"
  echo "${local_version}"
  local remote_version
  remote_version="$(curl -fsL https://raw.githubusercontent.com/sschmid/bee/master/version.txt)"
  if [[ -n "${remote_version}" && "${remote_version}" != "${local_version}" ]]; then
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
    local local_version
    local_version="$(cat "${BEE_HOME}/version.txt")"
    {
      echo '#!/usr/bin/env bash'
      echo "BEE_PROJECT=\"$(basename "${PWD}")\""
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
  resolve_plugin_specs "$@"
  for spec in "${BEE_PLUGIN_SPECS_RESULT[@]}"; do
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
    resolve_plugin_specs "$1"
    for spec in "${BEE_PLUGIN_SPECS_RESULT[@]}"; do
      source "${spec}"
      local log="${BEE_PLUGINS_HOME}/${BEE_PLUGIN_NAME}/${BEE_PLUGIN_VERSION}/CHANGELOG.md"
      unload_plugin_spec
      if [[ -f "${log}" ]]; then
        less "${log}"
      else
        echo "Changelog for $1 doesn't exist"
      fi
    done
  else
    less "${BEE_SYSTEM_HOME}/CHANGELOG.md"
  fi
}

bee_help_uninstall=("uninstall | uninstall bee from your system")
uninstall() {
  if [[ "${BEE_SILENT}" == false ]]; then
    echo "You're about to uninstall bee from your system."
    echo "Do you want to continue? (yes | no)"
    read -r a
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
  local commands=()
  for help_var in $(compgen -v bee_help_); do
    help_var+="[@]"
    for entry in "${!help_var}"; do
      commands+=("  ${entry}")
    done
  done

  local local_version
  local_version="$(cat "${BEE_HOME}/version.txt")"
  echo "🐝 bee ${local_version} - plugin-based bash automation"
  echo ""
  echo "usage: bee [-s(ilent) -v(erbose)] <command> [<args>]"
  echo ""
  echo -e "${commands[*]}" | column -s '|' -t
  echo ""
  echo "EXAMPLE"
  echo "  bee slack::message"
  echo "  bee version::bump_minor"
  echo "  bee ios::upload"
}

help_plugin() {
  resolve_plugin_specs "$1"
  for spec in "${BEE_PLUGIN_SPECS_RESULT[@]}"; do
    source "${spec}"
    local readme="${BEE_PLUGINS_HOME}/${BEE_PLUGIN_NAME}/${BEE_PLUGIN_VERSION}/README.md"
    unload_plugin_spec
    if [[ -f "${readme}" ]]; then
      less "${readme}"
    else
      echo "Help for $1 doesn't exist"
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
  if [[ "${BEE_JOB_RUNNING}" == true ]]; then
    job_int
  fi
  for t in "${BEE_INT_TRAPS[@]}"; do
    "$t"
  done
}

bee_term() {
  BEE_CANCELED=true
  if [[ "${BEE_JOB_RUNNING}" == true ]]; then
    job_term
  fi
  for t in "${BEE_TERM_TRAPS[@]}"; do
    "$t"
  done
}

bee_exit() {
  local exit_code=$?
  if [[ "${BEE_JOB_RUNNING}" == true ]]; then
    job_exit "${exit_code}"
  fi
  for t in "${BEE_EXIT_TRAPS[@]}"; do
    "$t"
  done
  if [[ "${BEE_SILENT}" == false ]] && (( BEE_MODE == BEE_MODE_COMMAND )); then
    if (( exit_code == 0 )) && [[ "${BEE_CANCELED}" == false ]]; then
      log "bzzzz ($(( SECONDS - T )) seconds)"
    else
      log "🔴 bzzzz ($(( SECONDS - T )) seconds)"
    fi
  fi
}

main() {
  trap bee_int INT
  trap bee_term TERM
  trap bee_exit EXIT

  if [[ -v PLUGINS ]]; then
    plugins_with_dependencies "${PLUGINS[@]}"
    source_plugins "${PLUGINS_WITH_DEPENDENCIES_RESULT[@]}"
  fi

  while getopts ":sv" arg; do
    case $arg in
      s) BEE_SILENT=true ;;
      v) set -x ;;
      *)
        log_error "${FUNCNAME[0]} Invalid option -${OPTARG}"
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
      plugins_with_dependencies "${cmd}"
      source_plugins "${PLUGINS_WITH_DEPENDENCIES_RESULT[@]}"
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
