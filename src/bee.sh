#!/usr/bin/env bash

# ################################################################################
# # compatibility
# ################################################################################

pbcopy_compat(){
  if command -v pbcopy &> /dev/null; then
    pbcopy "$@"
  else
    return 1
  fi
}

open_compat(){
  if command -v open &> /dev/null; then
    open "$@"
  else
    echo "$@"
  fi
}

sha256_compat() {
  if command -v shasum &> /dev/null; then
    shasum -a 256 "$@"
  elif command -v sha256sum &> /dev/null; then
    sha256sum "$@"
  else
    echo "🔴 ${FUNCNAME[0]}: couldn't find a command to do sha 256" >&2
    exit 1
  fi
}

column_compat() {
  if command -v column &> /dev/null; then
    column -s '|' -t "$@"
  else
    awk -F '|' '{ printf "%-29s%s\n", $1, $2 }' "$@"
  fi
}

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
  if ! command -v "$1" &> /dev/null; then
    log_error "$1 not found! $1 is required."
    exit 1
  fi
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
  tput civis &> /dev/null || true
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
    tput cnorm &> /dev/null || true
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
    BEE_JOB_LOGFILE="${BEE_RESOURCES}/logs/$(date -u '+%Y-%m-%d-%H-%M-%S')-job-${BEE_JOB_TITLE}-${RANDOM}${RANDOM}.log"
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
    if [[ "${url}" =~ ^https:// ]]; then
      LOCAL_REGISTRY_PATH_RESULT="$(dirname "${url#https://}")/$(basename "${url}" .git)"
      LOCAL_REGISTRY_PATH_CACHE["${url}"]="${LOCAL_REGISTRY_PATH_RESULT}"
    elif [[ "${url}" =~ ^git@ ]]; then
      local path="${url#git@}"
      path="${path//://}"
      LOCAL_REGISTRY_PATH_RESULT="$(dirname "${path}")/$(basename "${url}" .git)"
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

REGISTRY_CACHES_RESULT=()
resolve_registry_caches() {
  REGISTRY_CACHES_RESULT=()
  for url in "$@"; do
    build_local_registry_path "${url}"
    if [[ -n "${LOCAL_REGISTRY_PATH_RESULT}" ]]; then
      REGISTRY_CACHES_RESULT+=("${BEE_REGISTRIES_HOME}/${LOCAL_REGISTRY_PATH_RESULT}")
    fi
  done
}

LINT_CACHE_RESULT=""
resolve_lint_cache() {
  LINT_CACHE_RESULT=""
  build_local_registry_path "$1"
  if [[ -n "${LOCAL_REGISTRY_PATH_RESULT}" ]]; then
    LINT_CACHE_RESULT="${BEE_LINT_HOME}/${LOCAL_REGISTRY_PATH_RESULT}"
  fi
}

bee_help_pull=("pull [<urls>] | update plugin registries")
PULL_CACHE=false
pull() {
  if [[ "${PULL_CACHE}" == false ]]; then
    PULL_CACHE=true
    log "Pulling registries"
    for url in "${@:-"${BEE_PLUGIN_REGISTRIES[@]}"}"; do
      resolve_registry_caches "${url}"
      if [[ -n "${REGISTRY_CACHES_RESULT}" ]]; then
        if [[ -d "${REGISTRY_CACHES_RESULT}" ]]; then
          pushd "${REGISTRY_CACHES_RESULT}" > /dev/null
            git pull &
          popd > /dev/null
        else
          git clone "${url}" "${REGISTRY_CACHES_RESULT}" &
        fi
      fi
    done
    wait
  fi
}

################################################################################
# plugins
################################################################################

BEE_GIT_MODE="https"
BEE_PLUGIN_SOURCE=""

set_plugin_source() {
  if [[ "${BEE_GIT_MODE}" == "https" ]]; then
    BEE_PLUGIN_SOURCE="${BEE_PLUGIN_SOURCE_HTTPS}"
  elif [[ "${BEE_GIT_MODE}" == "ssh" ]]; then
    BEE_PLUGIN_SOURCE="${BEE_PLUGIN_SOURCE_SSH}"
  else
    BEE_PLUGIN_SOURCE=""
  fi
}

declare -A PLUGIN_SPECS_CACHE=()
PLUGIN_SPECS_RESULT=()
resolve_plugin_specs() {
  PLUGIN_SPECS_RESULT=()
  resolve_registry_caches "${BEE_PLUGIN_REGISTRIES[@]}"
  for plugin in "$@"; do
    if [[ ! -v PLUGIN_SPECS_CACHE["${plugin}"] || "${PLUGIN_SPECS_CACHE["${plugin}"]}" == false ]]; then
      local plugin_name="${plugin%:*}"
      local plugin_version="${plugin##*:}"
      local found=false
      if [[ "${plugin_name}" == "${plugin_version}" ]]; then
        # find latest
        for cache in "${REGISTRY_CACHES_RESULT[@]}"; do
          local plugin_path="${cache}/${plugin_name}"
          if [[ -d "${plugin_path}" ]]; then
            local versions=("${plugin_path}"/*/)
            if [[ -d "${versions}" ]]; then
              for ((i=0; i<${#versions[@]}; i++)); do
                versions[i]="$(basename "${versions[i]}")"
              done
              plugin_version="$(echo "${versions[*]}" | sort -V | tail -n 1)"
              plugin_path="${plugin_path}/${plugin_version}/plugin.sh"
              if [[ -f "${plugin_path}" ]]; then
                found=true
                PLUGIN_SPECS_RESULT+=("${plugin_path}")
                PLUGIN_SPECS_CACHE["${plugin}"]="${plugin_path}"
                PLUGIN_SPECS_CACHE["${plugin_name}:${plugin_version}"]="${plugin_path}"
                break
              fi
            fi
          fi
        done
      else
        for cache in "${REGISTRY_CACHES_RESULT[@]}"; do
          local plugin_path="${cache}/${plugin_name}/${plugin_version}/plugin.sh"
          if [[ -f "${plugin_path}" ]]; then
            found=true
            PLUGIN_SPECS_RESULT+=("${plugin_path}")
            PLUGIN_SPECS_CACHE["${plugin}"]="${plugin_path}"
            break
          fi
        done
      fi

      if [[ "${found}" == false ]]; then
        if [[ ! -v PLUGIN_SPECS_CACHE["${plugin}"] ]]; then
          log_warn "Could not find plugin ${plugin}"
        fi
        PLUGIN_SPECS_CACHE["${plugin}"]=false
      fi
    elif [[ "${PLUGIN_SPECS_CACHE["${plugin}"]}" != false ]]; then
      PLUGIN_SPECS_RESULT+=("${PLUGIN_SPECS_CACHE["${plugin}"]}")
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
  unset BEE_PLUGIN_SOURCE_HTTPS
  unset BEE_PLUGIN_SOURCE_SSH
  unset BEE_PLUGIN_SOURCE
  unset BEE_PLUGIN_TAG
  unset BEE_PLUGIN_SHA256
  unset BEE_PLUGIN_DEPENDENCIES
}

bee_help_hash=("hash <path> | generate hash for a plugin")
HASH_RESULT=""
hash() {
  HASH_RESULT=""
  local path="$1"
  local hashes=()
  pushd "${path}" > /dev/null
    shopt -s globstar
    for p in **/*; do
      if [[ -f "$p" ]]; then
        local hash
        hash="$(sha256_compat "$p")"
        echo "${hash}"
        hashes+=("${hash// */}")
      fi
    done
  popd > /dev/null
  local all
  all="$(echo "${hashes[*]}" | sort | sha256_compat)"
  echo "${all}"
  HASH_RESULT="${all// */}"
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
  set_plugin_source

  lint_var_value BEE_PLUGIN_NAME "$(basename "$(dirname "$(dirname "${spec}")")")"
  lint_var_value BEE_PLUGIN_VERSION "$(basename "$(dirname "${spec}")")"
  lint_var BEE_PLUGIN_LICENSE
  lint_var BEE_PLUGIN_HOMEPAGE
  lint_var BEE_PLUGIN_AUTHORS
  lint_var BEE_PLUGIN_INFO
  lint_var BEE_PLUGIN_SOURCE_HTTPS
  lint_var BEE_PLUGIN_SOURCE_SSH
  lint_var BEE_PLUGIN_TAG
  lint_var BEE_PLUGIN_SHA256

  if [[ -v BEE_PLUGIN_DEPENDENCIES ]]; then
    echo -e "\033[32mBEE_PLUGIN_DEPENDENCIES ${BEE_PLUGIN_DEPENDENCIES[*]} ✔︎\033[0m"
  else
    echo -e "\033[32mBEE_PLUGIN_DEPENDENCIES no dependencies ✔︎\033[0m"
  fi

  if [[ -v BEE_PLUGIN_SOURCE && -v BEE_PLUGIN_TAG && -v BEE_PLUGIN_SHA256 &&
        -n "${BEE_PLUGIN_SOURCE}" && -n "${BEE_PLUGIN_TAG}" && -n "${BEE_PLUGIN_SHA256}"
      ]]; then
    resolve_lint_cache "${BEE_PLUGIN_SOURCE}"
    if [[ -n "${LINT_CACHE_RESULT}" ]]; then
      if [[ -d "${LINT_CACHE_RESULT}" ]]; then
        pushd "${LINT_CACHE_RESULT}" > /dev/null
          job "BEE_PLUGIN_SOURCE" git fetch || true
        popd > /dev/null
      else
        job "BEE_PLUGIN_SOURCE" git clone "${BEE_PLUGIN_SOURCE}" "${LINT_CACHE_RESULT}" || true
      fi
      if [[ -d "${LINT_CACHE_RESULT}" ]]; then
        pushd "${LINT_CACHE_RESULT}" > /dev/null
          if git show-ref -q --tags --verify -- "refs/tags/${BEE_PLUGIN_TAG}"; then
            echo -e "\033[32mBEE_PLUGIN_TAG ${BEE_PLUGIN_TAG} ✔︎\033[0m"
            git checkout -q "${BEE_PLUGIN_TAG}"
            hash . > /dev/null
            lint_var_value BEE_PLUGIN_SHA256 "${HASH_RESULT}"
          else
            echo -e "\033[31mBEE_PLUGIN_TAG is set to ${BEE_PLUGIN_TAG} but doesn't exist in ${BEE_PLUGIN_SOURCE}\033[0m"
            echo -e "\033[31mBEE_PLUGIN_SHA256 (BEE_PLUGIN_TAG failed)\033[0m"
          fi
        popd > /dev/null
      else
        echo -e "\033[31mBEE_PLUGIN_TAG (BEE_PLUGIN_SOURCE failed)\033[0m"
        echo -e "\033[31mBEE_PLUGIN_SHA256 (BEE_PLUGIN_SOURCE failed)\033[0m"
      fi
    else
      echo -e "\033[31mBEE_PLUGIN_SOURCE ${BEE_PLUGIN_SOURCE}\033[0m"
      echo -e "\033[31mBEE_PLUGIN_TAG (BEE_PLUGIN_SOURCE failed)\033[0m"
      echo -e "\033[31mBEE_PLUGIN_SHA256 (BEE_PLUGIN_SOURCE failed)\033[0m"
    fi
  fi

  unload_plugin_spec
}

bee_help_info=("info [-r] <plugin> | show (r)aw plugin spec info")
info() {
  local show_raw=false
  while getopts ":r" arg; do
    case $arg in
      r) show_raw=true ;;
      *)
        log_error "${FUNCNAME[0]}: Invalid option -${OPTARG}"
        exit 1
        ;;
    esac
  done
  shift $(( OPTIND - 1 ))

  resolve_plugin_specs "$1"
  for spec in "${PLUGIN_SPECS_RESULT[@]}"; do
      echo "from:              ${spec}"
      echo "last modified:     $(date -r "${spec}")"
    if [[ "${show_raw}" == false ]]; then
      source "${spec}"
      echo "name:              ${BEE_PLUGIN_NAME}
version:           ${BEE_PLUGIN_VERSION}
license:           ${BEE_PLUGIN_LICENSE}
homepage:          ${BEE_PLUGIN_HOMEPAGE}
authors:           ${BEE_PLUGIN_AUTHORS}
summary:           ${BEE_PLUGIN_INFO}
source (https):    ${BEE_PLUGIN_SOURCE_HTTPS}
source (ssh):      ${BEE_PLUGIN_SOURCE_SSH}
tag:               ${BEE_PLUGIN_TAG}
sha256:            ${BEE_PLUGIN_SHA256}
dependencies:      ${BEE_PLUGIN_DEPENDENCIES[@]:-"none"}"
      unload_plugin_spec
    else
      cat "${spec}"
    fi
  done
}

bee_help_depstree=("depstree [<plugins>] | list dependencies hierarchy")
declare -A DEPSTREE_CACHE=()
DEPSTREE_INDENT=""
depstree() {
  resolve_plugin_specs ${@:-"${PLUGINS[@]}"}
  local specs=("${PLUGIN_SPECS_RESULT[@]}")
  for spec in "${specs[@]}"; do
    source "${spec}"
    echo "${DEPSTREE_INDENT}${BEE_PLUGIN_NAME}:${BEE_PLUGIN_VERSION}"
    if [[ ! -v DEPSTREE_CACHE["${spec}"] ]]; then
      DEPSTREE_CACHE["${spec}"]=true
      if [[ -v BEE_PLUGIN_DEPENDENCIES ]]; then
        DEPSTREE_INDENT="${DEPSTREE_INDENT/'├'/'|'}"
        DEPSTREE_INDENT="${DEPSTREE_INDENT//'─'/' '}├── "
        local dependencies=("${BEE_PLUGIN_DEPENDENCIES[@]}")
        unload_plugin_spec
        depstree "${dependencies[@]}"
        if [[ "${#DEPSTREE_INDENT}" -ge 8 ]]; then
          DEPSTREE_INDENT="${DEPSTREE_INDENT:0:-8}├── "
        else
          DEPSTREE_INDENT=""
        fi
      else
        unload_plugin_spec
      fi
    else
      unload_plugin_spec
    fi
  done
}

declare -A DEPS_CACHE=()
DEPS_RESULT=()
deps_recursive() {
  resolve_plugin_specs "$@"
  local specs=("${PLUGIN_SPECS_RESULT[@]}")
  for spec in "${specs[@]}"; do
    if [[ ! -v DEPS_CACHE["${spec}"] ]]; then
      DEPS_CACHE["${spec}"]=true
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

PLUGINS_WITH_DEPENDENCIES_RESULT=()
plugins_with_dependencies() {
  PLUGINS_WITH_DEPENDENCIES_RESULT=()
  resolve_plugin_specs "$@"
  for spec in "${PLUGIN_SPECS_RESULT[@]}"; do
    source "${spec}"
    PLUGINS_WITH_DEPENDENCIES_RESULT+=("${BEE_PLUGIN_NAME}:${BEE_PLUGIN_VERSION}")
    unload_plugin_spec
  done

  DEPS_CACHE=()
  DEPS_RESULT=()
  deps_recursive "$@"
  if [[ "${#DEPS_RESULT[@]}" -gt 0 ]]; then
    DEPS_RESULT=($(echo "${DEPS_RESULT[*]}" | sort -u))
    PLUGINS_WITH_DEPENDENCIES_RESULT+=("${DEPS_RESULT[@]}")
  fi

  if [[ ${#PLUGINS_WITH_DEPENDENCIES_RESULT[@]} -gt 0 ]]; then
    PLUGINS_WITH_DEPENDENCIES_RESULT=($(echo "${PLUGINS_WITH_DEPENDENCIES_RESULT[*]}" | sort -u))
  fi
}

bee_help_install=("install [<plugins>] | install plugins")
declare -A INSTALL_CACHE=()
install() {
  pull || true
  plugins_with_dependencies ${@:-"${PLUGINS[@]}"}
  resolve_plugin_specs "${PLUGINS_WITH_DEPENDENCIES_RESULT[@]}"
  for spec in "${PLUGIN_SPECS_RESULT[@]}"; do
    if [[ ! -v INSTALL_CACHE["${spec}"] ]]; then
      INSTALL_CACHE["${spec}"]=true
      source "${spec}"
      set_plugin_source
      local path="${BEE_PLUGINS_HOME}/${BEE_PLUGIN_NAME}/${BEE_PLUGIN_VERSION}"
      if [[ ! -d "${path}" ]]; then
        git -c advice.detachedHead=false clone -q --depth 1 --branch "${BEE_PLUGIN_TAG}" "${BEE_PLUGIN_SOURCE}" "${path}"
        echo -e "\033[32m${BEE_PLUGIN_NAME}:${BEE_PLUGIN_VERSION} ✔︎\033[0m"
      else
        echo "${BEE_PLUGIN_NAME}:${BEE_PLUGIN_VERSION}"
      fi
      hash "${path}" > /dev/null
      if [[ "${HASH_RESULT}" != "${BEE_PLUGIN_SHA256}" ]]; then
        if [[ "${BEE_FORCE}" == false ]]; then
          log_warn "${BEE_PLUGIN_NAME}:${BEE_PLUGIN_VERSION} SHA256 mismatch." "Deleting ${path}" \
            "Use 'bee -f install' to install anyway and proceed at your own risk." \
            "Use 'bee info -r ${BEE_PLUGIN_NAME}:${BEE_PLUGIN_VERSION}' to inspect the plugin spec."
          rm -rf "${path}"
        else
          log_warn "${BEE_PLUGIN_NAME}:${BEE_PLUGIN_VERSION} SHA256 mismatch." \
          "Plugin was tampered with or version has been modified. Authenticity is not guaranteed." \
          "Consider deleting ${path} and install again."
        fi
      fi
      unload_plugin_spec
    fi
  done
}

bee_help_reinstall=("reinstall [<plugins>] | reinstall plugins")
reinstall() {
  plugins_with_dependencies ${@:-"${PLUGINS[@]}"}
  resolve_plugin_specs "${PLUGINS_WITH_DEPENDENCIES_RESULT[@]}"
  for spec in "${PLUGIN_SPECS_RESULT[@]}"; do
    if [[ ! -v INSTALL_CACHE["${spec}"] ]]; then
      INSTALL_CACHE["${spec}"]=true
      source "${spec}"
      local path="${BEE_PLUGINS_HOME}/${BEE_PLUGIN_NAME}/${BEE_PLUGIN_VERSION}"
      if [[ -d "${path}" ]]; then
        echo "Uninstalling ${BEE_PLUGIN_NAME}:${BEE_PLUGIN_VERSION}"
        rm -rf "${path}"
      fi
      unload_plugin_spec
    fi
  done
  INSTALL_CACHE=()
  install "$@"
}

source_plugins() {
  resolve_plugin_specs "$@"
  for spec in "${PLUGIN_SPECS_RESULT[@]}"; do
    source "${spec}"
    local path="${BEE_PLUGINS_HOME}/${BEE_PLUGIN_NAME}/${BEE_PLUGIN_VERSION}/${BEE_PLUGIN_NAME}.sh"
    local plugin="${BEE_PLUGIN_NAME}:${BEE_PLUGIN_VERSION}"
    unload_plugin_spec
    if [[ ! -f "${path}" ]]; then
      install "${plugin}"
    fi
    if [[ -f "${path}" ]]; then
      source "${path}"
    fi
  done
}

bee_help_plugins=("plugins [-a -v -i] | list (a)ll plugins with (v)ersion and (i)nfo")
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
        log_error "${FUNCNAME[0]}: Invalid option -${OPTARG}"
        exit 1
        ;;
    esac
  done
  shift $(( OPTIND - 1 ))

  local list=""
  if [[ "${show_all}" == false ]]; then
    plugins_with_dependencies "${PLUGINS[@]}"
    resolve_plugin_specs "${PLUGINS_WITH_DEPENDENCIES_RESULT[@]}"
    for spec in "${PLUGIN_SPECS_RESULT[@]}"; do
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
    for cache in "${REGISTRY_CACHES_RESULT[@]}"; do
      local plugins=("${cache}"/*/)
      if [[ -d "${plugins}" ]]; then
        for ((i=0; i<${#plugins[@]}; i++)); do
          plugins[i]="$(basename "${plugins[i]}")"
        done
        resolve_plugin_specs "${plugins[@]}"
        for spec in "${PLUGIN_SPECS_RESULT[@]}"; do
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
  echo -ne "${list}" | column_compat
}

bee_help_res=("res <plugins> | copy plugin resources into resources dir")
res() {
  resolve_plugin_specs "$@"
  for spec in "${PLUGIN_SPECS_RESULT[@]}"; do
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
  for spec in "${PLUGIN_SPECS_RESULT[@]}"; do
    source "${spec}"
    local new_func="${BEE_PLUGIN_NAME}::_new"
    unload_plugin_spec
    if [[ $(command -v "${new_func}") == "${new_func}" ]]; then
      template+="\n$("${new_func}")\n"
    fi
  done
  if [[ -n "${template}" ]]; then
    echo -ne "${template/'\n'/}"
    if echo -ne "${template/'\n'/}" | pbcopy_compat; then
      echo -e "\n(template has been copied to clipboard, please paste into your .beerc)"
    fi
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

bee_help_changelog=("changelog [<plugin>] | show changelog")
changelog() {
  if (( $# == 1 )); then
    resolve_plugin_specs "$1"
    for spec in "${PLUGIN_SPECS_RESULT[@]}"; do
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

bee_help_outdated=("outdated | list outdated plugin versions")
outdated() {
  pull || true
  resolve_plugin_specs "${PLUGINS[@]}"
  local specs=("${PLUGIN_SPECS_RESULT[@]}")
  for spec in "${specs[@]}"; do
    source "${spec}"
    local plugin_name="${BEE_PLUGIN_NAME}"
    local current_plugin_version_str="${BEE_PLUGIN_VERSION}"
    local current_plugin_version=${current_plugin_version_str//./}
    current_plugin_version="${current_plugin_version#0}"
    unload_plugin_spec
    resolve_plugin_specs "${plugin_name}"
    for s in "${PLUGIN_SPECS_RESULT[@]}"; do
      source "${s}"
      local latest_plugin_version_str="${BEE_PLUGIN_VERSION}"
      local latest_plugin_version=${latest_plugin_version_str//./}
      latest_plugin_version="${latest_plugin_version#0}"
      if (( latest_plugin_version > current_plugin_version )); then
        echo "${plugin_name}:${current_plugin_version_str} => ${plugin_name}:${latest_plugin_version_str}"
      else
        local path="${BEE_PLUGINS_HOME}/${BEE_PLUGIN_NAME}/${BEE_PLUGIN_VERSION}"
        hash "${path}" > /dev/null
        if [[ "${HASH_RESULT}" != "${BEE_PLUGIN_SHA256}" ]]; then
          echo "${plugin_name}:${current_plugin_version_str} => SHA256 mismatch! Use 'bee reinstall ${plugin_name}:${current_plugin_version_str}' to reinstall"
        fi
      fi
      unload_plugin_spec
    done
  done
}

bee_help_uninstall=("uninstall [-d <plugins>] | uninstall bee or plugins with (d)ependencies")
uninstall() {
  if (( $# == 0 )); then
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
  else
    local uninstall_deps=false
    while getopts ":d" arg; do
      case $arg in
        d) uninstall_deps=true ;;
        *)
          log_error "${FUNCNAME[0]}: Invalid option -${OPTARG}"
          exit 1
          ;;
      esac
    done
    shift $(( OPTIND - 1 ))

    if [[ "${uninstall_deps}" == false ]]; then
      resolve_plugin_specs "$@"
    else
      plugins_with_dependencies "$@"
      resolve_plugin_specs "${PLUGINS_WITH_DEPENDENCIES_RESULT[@]}"
    fi

    for spec in "${PLUGIN_SPECS_RESULT[@]}"; do
      source "${spec}"
      local path="${BEE_PLUGINS_HOME}/${BEE_PLUGIN_NAME}/${BEE_PLUGIN_VERSION}"
      if [[ -d "${path}" ]]; then
        echo "Uninstalling ${BEE_PLUGIN_NAME}:${BEE_PLUGIN_VERSION}"
        rm -rf "${path}"
      fi
      unload_plugin_spec
    done
  fi
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
  remote_version="$(wget -qO- https://raw.githubusercontent.com/sschmid/bee/master/version.txt 2> /dev/null)"
  if [[ -n "${remote_version}" && "${remote_version}" != "${local_version}" ]]; then
    echo "latest: ${remote_version} (run 'bee update' to update to ${remote_version})"
  fi
}

bee_help_wiki=("wiki | open wiki")
wiki() {
  open_compat "https://github.com/sschmid/bee/wiki"
}

bee_help_donate=("donate | bee is free, but powered by your donations")
donate() {
  open_compat "https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=M7WHTWP4GE75Y"
}

bee_help_commands=("commands [<search>] | list commands of enabled plugins")
commands() {
  compgen -A function \
    | grep --color=never '^[a-zA-Z]*::[a-zA-Z]' \
    | grep --color=never -- "$*" \
    || true
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
  echo "usage: bee [-s(ilent) -v(erbose) -f(orce) -p(ssh)] <command> [<args>]"
  echo ""
  echo -e "${commands[*]}" | column_compat
  echo ""
  echo "EXAMPLE"
  echo "  bee slack::message"
  echo "  bee version::bump_minor"
  echo "  bee ios::upload"
}

help_plugin() {
  resolve_plugin_specs "$1"
  for spec in "${PLUGIN_SPECS_RESULT[@]}"; do
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

bee_help_help=("help [<plugin>] | show usage")
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
BEE_FORCE=false
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

  while getopts ":svfp" arg; do
    case $arg in
      s) BEE_SILENT=true ;;
      v) set -x ;;
      f) BEE_FORCE=true ;;
      p) BEE_GIT_MODE="ssh" ;;
      *)
        log_error "${FUNCNAME[0]}: Invalid option -${OPTARG}"
        exit 1
        ;;
    esac
  done
  shift $(( OPTIND - 1 ))

  if [[ -v PLUGINS ]]; then
    plugins_with_dependencies "${PLUGINS[@]}"
    source_plugins "${PLUGINS_WITH_DEPENDENCIES_RESULT[@]}"
  fi

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
