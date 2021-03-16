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

declare -a BEE_SPINNER_FRAMES=('🐝' ' 🐝' '  🐝' '   🐝' '    🐝' '     🐝' '      🐝' '       🐝' '        🐝' '         🐝' '        🐝' '       🐝' '      🐝' '     🐝' '    🐝' '   🐝' '  🐝' ' 🐝' '🐝')
BEE_SPINNER_INTERVAL=0.1

declare -i BEE_SPINNER_PID=0
declare -i BEE_JOB_RUNNING=0
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
  if [[ ${BEE_SPINNER_PID} -ne 0 ]]; then
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

declare -a bee_help_job=("job <title> <command> | run a command as a job")
job() {
  BEE_JOB_RUNNING=1
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
  BEE_JOB_RUNNING=0
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
  local -i exit_code=$1
  if [[ ${exit_code} -ne 0 ]]; then
    stop_spinner
    echo -e "\r\033[2K\033[0;31m${BEE_JOB_TITLE} ✗\033[0m"
  fi
}

################################################################################
# registries
################################################################################

BEE_REGISTRIES_HOME="${HOME}/.bee/caches/registries"
BEE_REGISTRIES_TS="${HOME}/.bee/caches/registries/.ts"
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

declare -a REGISTRY_CACHES_RESULT=()
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

declare -a bee_help_pull=("pull [<urls>] | update plugin registries")
pull() {
  local -i ts=0 now
  now=$(date +"%s")
  if [[ ${BEE_FORCE} -eq 0 && -f "${BEE_REGISTRIES_TS}" ]]; then
    ts=$(cat "${BEE_REGISTRIES_TS}")
  fi
  if (( now - ts > 300 )); then
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
    echo "${now}" > "${BEE_REGISTRIES_TS}"
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
declare -a PLUGIN_SPECS_RESULT=()
resolve_plugin_specs() {
  PLUGIN_SPECS_RESULT=()
  resolve_registry_caches "${BEE_PLUGIN_REGISTRIES[@]}"
  local plugin_name plugin_version plugin_path
  local -a versions
  local -i found=0
  for plugin in "$@"; do
    if [[ ! -v PLUGIN_SPECS_CACHE["${plugin}"] || "${PLUGIN_SPECS_CACHE["${plugin}"]}" == "false" ]]; then
      plugin_name="${plugin%:*}"
      plugin_version="${plugin##*:}"
      found=0
      if [[ "${plugin_name}" == "${plugin_version}" ]]; then
        # find latest
        for cache in "${REGISTRY_CACHES_RESULT[@]}"; do
          plugin_path="${cache}/${plugin_name}"
          if [[ -d "${plugin_path}" ]]; then
            versions=("${plugin_path}"/*/)
            if [[ -d "${versions}" ]]; then
              for ((i=0; i<${#versions[@]}; i++)); do
                versions[i]="$(basename "${versions[i]}")"
              done
              plugin_version="$(echo "${versions[*]}" | sort -V | tail -n 1)"
              plugin_path="${plugin_path}/${plugin_version}/plugin.sh"
              if [[ -f "${plugin_path}" ]]; then
                found=1
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
          plugin_path="${cache}/${plugin_name}/${plugin_version}/plugin.sh"
          if [[ -f "${plugin_path}" ]]; then
            found=1
            PLUGIN_SPECS_RESULT+=("${plugin_path}")
            PLUGIN_SPECS_CACHE["${plugin}"]="${plugin_path}"
            break
          fi
        done
      fi

      if [[ ${found} -eq 0 ]]; then
        if [[ ! -v PLUGIN_SPECS_CACHE["${plugin}"] ]]; then
          log_warn "Could not find plugin ${plugin}"
        fi
        PLUGIN_SPECS_CACHE["${plugin}"]="false"
      fi
    elif [[ "${PLUGIN_SPECS_CACHE["${plugin}"]}" != "false" ]]; then
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

declare -a bee_help_hash=("hash <path> | generate hash for a plugin")
HASH_RESULT=""
hash() {
  HASH_RESULT=""
  local path="$1" file_hash all
  local -a hashes=()
  pushd "${path}" > /dev/null
    shopt -s globstar
    for f in **/*; do
      if [[ -f "$f" ]]; then
        file_hash="$(sha256_compat "$f")"
        echo "${file_hash}"
        hashes+=("${file_hash// */}")
      fi
    done
  popd > /dev/null
  all="$(echo "${hashes[*]}" | sort | sha256_compat)"
  echo "${all}"
  HASH_RESULT="${all// */}"
}

lint_var() {
  for var in "$@"; do
    if [[ ! -v ${var} || -z "${!var}" ]]; then
      echo -e "\033[31m${var} is required\033[0m"
    else
      echo -e "\033[32m${var} ✔︎\033[0m"
    fi
  done
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

declare -a bee_help_lint=("lint <spec> | validate plugin specification")
lint() {
  local spec="$1"
  source "${spec}"
  set_plugin_source

  lint_var_value BEE_PLUGIN_NAME "$(basename "$(dirname "$(dirname "${spec}")")")"
  lint_var_value BEE_PLUGIN_VERSION "$(basename "$(dirname "${spec}")")"
  lint_var BEE_PLUGIN_LICENSE BEE_PLUGIN_HOMEPAGE BEE_PLUGIN_AUTHORS BEE_PLUGIN_INFO BEE_PLUGIN_SOURCE_HTTPS BEE_PLUGIN_SOURCE_SSH BEE_PLUGIN_TAG BEE_PLUGIN_SHA256

  if [[ -v BEE_PLUGIN_SOURCE && -v BEE_PLUGIN_TAG && -v BEE_PLUGIN_SHA256 &&
        -n "${BEE_PLUGIN_SOURCE}" && -n "${BEE_PLUGIN_TAG}" && -n "${BEE_PLUGIN_SHA256}"
      ]]
  then
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

            source "${BEE_PLUGIN_NAME}.sh"
            local deps_func="${BEE_PLUGIN_NAME}::_deps" deps="" spec_deps=""
            [[ $(command -v "${deps_func}") == "${deps_func}" ]] && deps="$(${deps_func})"
            [[ -v BEE_PLUGIN_DEPENDENCIES ]] && spec_deps="${BEE_PLUGIN_DEPENDENCIES[@]}"
            if [[ "${spec_deps}" != "${deps}" ]]; then
              echo -e "\033[31mBEE_PLUGIN_DEPENDENCIES is set to '${spec_deps}' but must be '${deps}'\033[0m"
            else
              echo -e "\033[32mBEE_PLUGIN_DEPENDENCIES ${spec_deps} ✔︎\033[0m"
            fi
          else
            echo -e "\033[31mBEE_PLUGIN_TAG is set to ${BEE_PLUGIN_TAG} but doesn't exist in ${BEE_PLUGIN_SOURCE}\033[0m"
            echo -e "\033[31mBEE_PLUGIN_SHA256 (BEE_PLUGIN_TAG failed)\033[0m"
            echo -e "\033[31mBEE_PLUGIN_DEPENDENCIES (BEE_PLUGIN_TAG failed)\033[0m"
          fi
        popd > /dev/null
      else
        echo -e "\033[31mBEE_PLUGIN_TAG (BEE_PLUGIN_SOURCE failed)\033[0m"
        echo -e "\033[31mBEE_PLUGIN_SHA256 (BEE_PLUGIN_SOURCE failed)\033[0m"
        echo -e "\033[31mBEE_PLUGIN_DEPENDENCIES (BEE_PLUGIN_SOURCE failed)\033[0m"
      fi
    else
      echo -e "\033[31mBEE_PLUGIN_SOURCE ${BEE_PLUGIN_SOURCE}\033[0m"
      echo -e "\033[31mBEE_PLUGIN_TAG (BEE_PLUGIN_SOURCE failed)\033[0m"
      echo -e "\033[31mBEE_PLUGIN_SHA256 (BEE_PLUGIN_SOURCE failed)\033[0m"
      echo -e "\033[31mBEE_PLUGIN_DEPENDENCIES (BEE_PLUGIN_SOURCE failed)\033[0m"
    fi
  fi

  unload_plugin_spec
}

declare -a bee_help_info=("info [-r] <plugin> | show (r)aw plugin spec info")
info() {
  local -i show_raw=0
  while getopts ":r" arg; do
    case $arg in
      r) show_raw=1 ;;
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
    if [[ ${show_raw} -eq 0 ]]; then
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

declare -a bee_help_depstree=("depstree [<plugins>] | list dependencies hierarchy")
declare -A DEPSTREE_CACHE=()
DEPSTREE_INDENT=""
depstree() {
  resolve_plugin_specs ${@:-"${PLUGINS[@]}"}
  local -a specs=("${PLUGIN_SPECS_RESULT[@]}") dependencies
  for spec in "${specs[@]}"; do
    source "${spec}"
    echo "${DEPSTREE_INDENT}${BEE_PLUGIN_NAME}:${BEE_PLUGIN_VERSION}"
    if [[ ! -v DEPSTREE_CACHE["${spec}"] ]]; then
      DEPSTREE_CACHE["${spec}"]=1
      if [[ -v BEE_PLUGIN_DEPENDENCIES ]]; then
        DEPSTREE_INDENT="${DEPSTREE_INDENT/'├'/'│'}"
        DEPSTREE_INDENT="${DEPSTREE_INDENT//'─'/' '}├── "
        dependencies=("${BEE_PLUGIN_DEPENDENCIES[@]}")
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
declare -a DEPS_RESULT=()
deps_recursive() {
  resolve_plugin_specs "$@"
  local -a specs=("${PLUGIN_SPECS_RESULT[@]}") dependencies
  for spec in "${specs[@]}"; do
    if [[ ! -v DEPS_CACHE["${spec}"] ]]; then
      DEPS_CACHE["${spec}"]=1
      source "${spec}"
      if [[ -v BEE_PLUGIN_DEPENDENCIES ]]; then
        dependencies=("${BEE_PLUGIN_DEPENDENCIES[@]}")
        unload_plugin_spec
        DEPS_RESULT+=("${dependencies[@]}")
        deps_recursive "${dependencies[@]}"
      else
        unload_plugin_spec
      fi
    fi
  done
}

declare -a PLUGINS_WITH_DEPENDENCIES_RESULT=()
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
    resolve_plugin_specs "${DEPS_RESULT[@]}"
    for spec in "${PLUGIN_SPECS_RESULT[@]}"; do
      source "${spec}"
      PLUGINS_WITH_DEPENDENCIES_RESULT+=("${BEE_PLUGIN_NAME}:${BEE_PLUGIN_VERSION}")
      unload_plugin_spec
    done
  fi

  if [[ ${#PLUGINS_WITH_DEPENDENCIES_RESULT[@]} -gt 0 ]]; then
    PLUGINS_WITH_DEPENDENCIES_RESULT=($(echo "${PLUGINS_WITH_DEPENDENCIES_RESULT[*]}" | sort -u))
  fi
}

declare -a bee_help_install=("install [<plugins>] | install plugins")
declare -A INSTALL_CACHE=()
install() {
  pull || true
  local path
  plugins_with_dependencies ${@:-"${PLUGINS[@]}"}
  resolve_plugin_specs "${PLUGINS_WITH_DEPENDENCIES_RESULT[@]}"
  for spec in "${PLUGIN_SPECS_RESULT[@]}"; do
    if [[ ! -v INSTALL_CACHE["${spec}"] ]]; then
      INSTALL_CACHE["${spec}"]=1
      source "${spec}"
      set_plugin_source
      path="${BEE_PLUGINS_HOME}/${BEE_PLUGIN_NAME}/${BEE_PLUGIN_VERSION}"
      {
        if [[ ! -d "${path}" ]]; then
          git -c advice.detachedHead=false clone -q --depth 1 --branch "${BEE_PLUGIN_TAG}" "${BEE_PLUGIN_SOURCE}" "${path}"
          echo -e "\033[32m${BEE_PLUGIN_NAME}:${BEE_PLUGIN_VERSION} ✔︎\033[0m"
        else
          echo "${BEE_PLUGIN_NAME}:${BEE_PLUGIN_VERSION}"
        fi
        hash "${path}" > /dev/null
        if [[ "${HASH_RESULT}" != "${BEE_PLUGIN_SHA256}" ]]; then
          if [[ ${BEE_FORCE} -eq 0 ]]; then
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
      } &
      unload_plugin_spec
    fi
  done
  wait
}

declare -a bee_help_reinstall=("reinstall [<plugins>] | reinstall plugins")
reinstall() {
  local path
  plugins_with_dependencies ${@:-"${PLUGINS[@]}"}
  resolve_plugin_specs "${PLUGINS_WITH_DEPENDENCIES_RESULT[@]}"
  for spec in "${PLUGIN_SPECS_RESULT[@]}"; do
    if [[ ! -v INSTALL_CACHE["${spec}"] ]]; then
      INSTALL_CACHE["${spec}"]=1
      source "${spec}"
      path="${BEE_PLUGINS_HOME}/${BEE_PLUGIN_NAME}/${BEE_PLUGIN_VERSION}"
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

declare -A SOURCE_PLUGINS_CACHE=()
source_plugins() {
  local path plugin
  resolve_plugin_specs "$@"
  for spec in "${PLUGIN_SPECS_RESULT[@]}"; do
    if [[ ! -v SOURCE_PLUGINS_CACHE["${spec}"] ]]; then
      SOURCE_PLUGINS_CACHE["${spec}"]=1
      source "${spec}"
      path="${BEE_PLUGINS_HOME}/${BEE_PLUGIN_NAME}/${BEE_PLUGIN_VERSION}/${BEE_PLUGIN_NAME}.sh"
      plugin="${BEE_PLUGIN_NAME}:${BEE_PLUGIN_VERSION}"
      unload_plugin_spec
      [[ ! -f "${path}" ]] && install "${plugin}"
      [[ -f "${path}" ]] && source "${path}"
    fi
  done
}

declare -a bee_help_plugins=("plugins [-a -v -i] | list (a)ll plugins with (v)ersion and (i)nfo")
plugins() {
  local -i show_all=0 show_version=0 show_info=0
  while getopts ":avi" arg; do
    case $arg in
      a) show_all=1 ;;
      v) show_version=1 ;;
      i) show_info=1 ;;
      *)
        log_error "${FUNCNAME[0]}: Invalid option -${OPTARG}"
        exit 1
        ;;
    esac
  done
  shift $(( OPTIND - 1 ))

  local list=""
  local -a plugins
  if [[ ${show_all} -eq 0 ]]; then
    plugins_with_dependencies "${PLUGINS[@]}"
    resolve_plugin_specs "${PLUGINS_WITH_DEPENDENCIES_RESULT[@]}"
    for spec in "${PLUGIN_SPECS_RESULT[@]}"; do
      source "${spec}"
      list+="${BEE_PLUGIN_NAME}"
      [[ ${show_version} -ne 0 ]] && list+=":${BEE_PLUGIN_VERSION}"
      [[ ${show_info} -ne 0 ]] && list+=" | ${BEE_PLUGIN_INFO}"
      list+="\n"
      unload_plugin_spec
    done
  else
    resolve_registry_caches "${BEE_PLUGIN_REGISTRIES[@]}"
    for cache in "${REGISTRY_CACHES_RESULT[@]}"; do
      plugins=("${cache}"/*/)
      if [[ -d "${plugins}" ]]; then
        for ((i=0; i<${#plugins[@]}; i++)); do
          plugins[i]="$(basename "${plugins[i]}")"
        done
        resolve_plugin_specs "${plugins[@]}"
        for spec in "${PLUGIN_SPECS_RESULT[@]}"; do
          source "${spec}"
          list+="${BEE_PLUGIN_NAME}"
          [[ ${show_version} -ne 0 ]] && list+=":${BEE_PLUGIN_VERSION}"
          [[ ${show_info} -ne 0 ]] && list+=" | ${BEE_PLUGIN_INFO}"
          list+="\n"
          unload_plugin_spec
        done
      fi
    done
  fi
  echo -ne "${list}" | column_compat
}

declare -a bee_help_res=("res <plugins> | copy plugin resources into resources dir")
res() {
  local resources_dir target_dir
  resolve_plugin_specs "$@"
  for spec in "${PLUGIN_SPECS_RESULT[@]}"; do
    source "${spec}"
    resources_dir="${BEE_PLUGINS_HOME}/${BEE_PLUGIN_NAME}/${BEE_PLUGIN_VERSION}/resources"
    if [[ -d "${resources_dir}" ]]; then
      target_dir="${BEE_RESOURCES}/${BEE_PLUGIN_NAME}"
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
  local template="" new_func
  resolve_plugin_specs "$@"
  for spec in "${PLUGIN_SPECS_RESULT[@]}"; do
    source "${spec}"
    new_func="${BEE_PLUGIN_NAME}::_new"
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

declare -a bee_help_new=(
  "new | create new .beerc"
  "new <plugins> | show code templates for plugins"
)
new() {
  if [[ $# -eq 0 ]]; then
    new_bee
  else
    new_plugin "$@"
  fi
}

declare -a bee_help_changelog=("changelog [<plugin>] | show changelog")
changelog() {
  if [[ $# -eq 1 ]]; then
    local log
    resolve_plugin_specs "$1"
    for spec in "${PLUGIN_SPECS_RESULT[@]}"; do
      source "${spec}"
      log="${BEE_PLUGINS_HOME}/${BEE_PLUGIN_NAME}/${BEE_PLUGIN_VERSION}/CHANGELOG.md"
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

declare -a bee_help_outdated=("outdated | list outdated plugin versions")
outdated() {
  pull || true
  resolve_plugin_specs "${PLUGINS[@]}"
  local -a specs=("${PLUGIN_SPECS_RESULT[@]}")
  local plugin_name current_plugin_version_str current_plugin_version latest_plugin_version_str latest_plugin_version path
  for spec in "${specs[@]}"; do
    source "${spec}"
    plugin_name="${BEE_PLUGIN_NAME}"
    current_plugin_version_str="${BEE_PLUGIN_VERSION}"
    current_plugin_version=${current_plugin_version_str//./}
    current_plugin_version="${current_plugin_version#0}"
    unload_plugin_spec
    resolve_plugin_specs "${plugin_name}"
    for s in "${PLUGIN_SPECS_RESULT[@]}"; do
      source "${s}"
      latest_plugin_version_str="${BEE_PLUGIN_VERSION}"
      latest_plugin_version=${latest_plugin_version_str//./}
      latest_plugin_version="${latest_plugin_version#0}"
      if [[ ${latest_plugin_version} -gt ${current_plugin_version} ]]; then
        echo "${plugin_name}:${current_plugin_version_str} => ${plugin_name}:${latest_plugin_version_str}"
      else
        path="${BEE_PLUGINS_HOME}/${BEE_PLUGIN_NAME}/${BEE_PLUGIN_VERSION}"
        {
          hash "${path}" > /dev/null
          if [[ "${HASH_RESULT}" != "${BEE_PLUGIN_SHA256}" ]]; then
            echo "${plugin_name}:${current_plugin_version_str} => SHA256 mismatch! Use 'bee reinstall ${plugin_name}:${current_plugin_version_str}' to reinstall"
          fi
        } &
      fi
      unload_plugin_spec
    done
  done
  wait
}

declare -a bee_help_uninstall=("uninstall [-d <plugins>] | uninstall bee or plugins with (d)ependencies")
uninstall() {
  if [[ $# -eq 0 ]]; then
    if [[ ${BEE_SILENT} -eq 0 ]]; then
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
    local -i uninstall_deps=0
    while getopts ":d" arg; do
      case $arg in
        d) uninstall_deps=1 ;;
        *)
          log_error "${FUNCNAME[0]}: Invalid option -${OPTARG}"
          exit 1
          ;;
      esac
    done
    shift $(( OPTIND - 1 ))

    if [[ ${uninstall_deps} -eq 0 ]]; then
      resolve_plugin_specs "$@"
    else
      plugins_with_dependencies "$@"
      resolve_plugin_specs "${PLUGINS_WITH_DEPENDENCIES_RESULT[@]}"
    fi

    local path
    for spec in "${PLUGIN_SPECS_RESULT[@]}"; do
      source "${spec}"
      path="${BEE_PLUGINS_HOME}/${BEE_PLUGIN_NAME}/${BEE_PLUGIN_VERSION}"
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

declare -a bee_help_batch=("batch <commands> | batch multiple commands with one bee call")
declare BATCH_COMMAND
declare -a BATCH_ARGS
batch() {
  BATCH_COMMAND=""
  BATCH_ARGS=()
  for command in "$@"; do
    set_batch_command "${command}"
    "${BATCH_COMMAND}" "${BATCH_ARGS[@]}"
  done
}

set_batch_command() {
  local IFS=" "
  local -a cmd=($@)
  BATCH_COMMAND="${cmd[0]}"
  BATCH_ARGS=(${cmd[@]:1})
}

builtin_commands() {
  local -a commands=("$(compgen -v bee_help_)")
  echo "${commands[@]//bee_help_/}"
}

declare -a bee_help_update=("update | update bee to the latest version")
update() {
  pushd "${BEE_SYSTEM_HOME}" > /dev/null
    git pull -q
    log "bee is up-to-date and ready to bzzzz"
  popd > /dev/null
}

declare -a bee_help_version=("version | show the current bee version")
version() {
  local local_version remote_version
  local_version="$(cat "${BEE_HOME}/version.txt")"
  echo "${local_version}"
  remote_version="$(wget -qO- https://raw.githubusercontent.com/sschmid/bee/master/version.txt 2> /dev/null)"
  if [[ -n "${remote_version}" && "${remote_version}" != "${local_version}" ]]; then
    echo "latest: ${remote_version} (run 'bee update' to update to ${remote_version})"
  fi
}

declare -a bee_help_wiki=("wiki | open wiki")
wiki() {
  open_compat "https://github.com/sschmid/bee/wiki"
}

declare -a bee_help_donate=("donate | bee is free, but powered by your donations")
donate() {
  open_compat "https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=M7WHTWP4GE75Y"
}

declare -a bee_help_commands=("commands [<search>] | list commands of enabled plugins")
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
  local -a commands=()
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
  echo "  bee version::bump_minor"
  echo "  bee unity::execute_method Build"
  echo "  bee ios::upload"
}

help_plugin() {
  resolve_plugin_specs "$1"
  local readme
  for spec in "${PLUGIN_SPECS_RESULT[@]}"; do
    source "${spec}"
    readme="${BEE_PLUGINS_HOME}/${BEE_PLUGIN_NAME}/${BEE_PLUGIN_VERSION}/README.md"
    unload_plugin_spec
    if [[ -f "${readme}" ]]; then
      less "${readme}"
    else
      echo "Help for $1 doesn't exist"
    fi
  done
}

declare -a bee_help_help=("help [<plugin>] | show usage")
help() {
  if [[ $# -eq 1 ]]; then
    help_plugin "$@"
  else
    help_bee
  fi
}

# ################################################################################
# # main
# ################################################################################

declare -a BEE_INT_TRAPS=()
declare -a BEE_TERM_TRAPS=()
declare -a BEE_EXIT_TRAPS=()
declare -i BEE_CANCELED=0
declare -i BEE_MODE_INTERNAL=0
declare -i BEE_MODE_COMMAND=1
declare -i BEE_MODE=${BEE_MODE_INTERNAL}
declare -i BEE_SILENT=0
declare -i BEE_FORCE=0
T=${SECONDS}

bee_int() {
  BEE_CANCELED=1
  [[ ${BEE_JOB_RUNNING} -ne 0 ]] && job_int
  for t in "${BEE_INT_TRAPS[@]}"; do
    "$t"
  done
}

bee_term() {
  BEE_CANCELED=1
  [[ ${BEE_JOB_RUNNING} -ne 0 ]] && job_term
  for t in "${BEE_TERM_TRAPS[@]}"; do
    "$t"
  done
}

bee_exit() {
  local -i exit_code=$?
  [[ ${BEE_JOB_RUNNING} -ne 0 ]] && job_exit ${exit_code}
  for t in "${BEE_EXIT_TRAPS[@]}"; do
    "$t"
  done
  if [[ ${BEE_SILENT} -eq 0 && ${BEE_MODE} -eq ${BEE_MODE_COMMAND} ]]; then
    if [[ ${exit_code} -eq 0 && ${BEE_CANCELED} -eq 0 ]]; then
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
      s) BEE_SILENT=1 ;;
      v) set -x ;;
      f) BEE_FORCE=1 ;;
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

  if [[ $# -gt 0 ]]; then
    local -a cmd=("$@")
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
