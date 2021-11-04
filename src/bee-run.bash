# shellcheck disable=SC1090
################################################################################
# modules
################################################################################
: "${BEE_MODULES_PATH:="${BEE_HOME}/src/modules"}"

BEE_LOAD_MODULE_NAME=""
declare -Ag BEE_LOAD_MODULE_LOADED=()
bee::load_module() {
  local module="$1"
  if [[ ! -v BEE_LOAD_MODULE_LOADED["${module}"] ]]; then
    local module_path="${BEE_MODULES_PATH}/${module}.bash"
    if [[ -f "${module_path}" ]]; then
      source "${module_path}"
      BEE_LOAD_MODULE_NAME="${module}"
    else
      BEE_LOAD_MODULE_NAME=""
    fi
    BEE_LOAD_MODULE_LOADED["${module}"]="${BEE_LOAD_MODULE_NAME}"
  else
    BEE_LOAD_MODULE_NAME="${BEE_LOAD_MODULE_LOADED["${module}"]}"
  fi
}

bee::run_module() {
  local module="$1"; shift
  "bee::${module}" "$@"
}

################################################################################
# plugins
################################################################################

bee::resolve() {
  local plugin="$1" plugins_path="$2" file="$3"
  local plugin_name="${plugin%:*}" plugin_version="${plugin##*:}" path
  if [[ "${plugin_name}" == "${plugin_version}" && -d "${plugins_path}/${plugin_name}" ]]; then
    plugin_version="$(basename "$(find "${plugins_path}/${plugin_name}" -mindepth 1 -maxdepth 1 -type d | sort -rV | head -n 1)")"
  fi
  path="${plugins_path}/${plugin_name}/${plugin_version}/${file}"
  [[ -f "${path}" ]] && echo -e "${plugin_name}\t${plugin_version}\t${path}"
}

BEE_RESOLVE_PLUGIN_NAME=""
BEE_RESOLVE_PLUGIN_VERSION=""
BEE_RESOLVE_PLUGIN_PATH=""
declare -Ag BEE_RESOLVE_PLUGIN_PATH_CACHE=()
bee::resolve_plugin() {
  local plugin="$1" plugin_name plugin_version plugin_path
  local -i found=0
  if [[ ! -v BEE_RESOLVE_PLUGIN_PATH_CACHE["${plugin}"] ]]; then
    for plugins_path in "${BEE_PLUGINS_PATHS[@]}"; do
      while read -r plugin_name plugin_version plugin_path; do
        BEE_RESOLVE_PLUGIN_NAME="${plugin_name}" BEE_RESOLVE_PLUGIN_VERSION="${plugin_version}" BEE_RESOLVE_PLUGIN_PATH="${plugin_path}"
        BEE_RESOLVE_PLUGIN_PATH_CACHE["${BEE_RESOLVE_PLUGIN_NAME}:${BEE_RESOLVE_PLUGIN_VERSION}"]="${BEE_RESOLVE_PLUGIN_PATH}"
        found=1
      done < <(bee::resolve "${plugin}" "${plugins_path}" "${plugin%:*}.bash")
      ((found)) && break
    done
    ((!found)) && BEE_RESOLVE_PLUGIN_NAME="" BEE_RESOLVE_PLUGIN_VERSION="" BEE_RESOLVE_PLUGIN_PATH=""
    BEE_RESOLVE_PLUGIN_PATH_CACHE["${plugin}"]="${BEE_RESOLVE_PLUGIN_PATH}"
  else
    BEE_RESOLVE_PLUGIN_PATH="${BEE_RESOLVE_PLUGIN_PATH_CACHE["${plugin}"]}"
  fi
}

BEE_LOAD_PLUGIN_NAME=""
declare -Ag BEE_LOAD_PLUGIN_LOADED=()
BEE_LOAD_PLUGIN_MISSING=()
bee::load_plugin() {
  BEE_LOAD_PLUGIN_MISSING=()
  bee::resolve_plugin "$1"
  if [[ -n "${BEE_RESOLVE_PLUGIN_PATH}" ]]; then
    BEE_LOAD_PLUGIN_NAME="${BEE_RESOLVE_PLUGIN_NAME}"
    bee::load_plugin_deps
    if [[ ${#BEE_LOAD_PLUGIN_MISSING[@]} -gt 0 ]]; then
      for missing in "${BEE_LOAD_PLUGIN_MISSING[@]}"; do
        bee::log_error "Missing plugin: '${missing}'"
      done
      exit 1
    fi
  else
    BEE_LOAD_PLUGIN_NAME=""
  fi
}

bee::load_plugin_deps() {
  if [[ ! -v BEE_LOAD_PLUGIN_LOADED["${BEE_RESOLVE_PLUGIN_PATH}"] ]]; then
    source "${BEE_RESOLVE_PLUGIN_PATH}"
    # shellcheck disable=SC2034
    BEE_LOAD_PLUGIN_LOADED["${BEE_RESOLVE_PLUGIN_PATH}"]=1
    local deps="${BEE_RESOLVE_PLUGIN_NAME}::deps"
    if [[ $(command -v "${deps}") == "${deps}" ]]; then
      for dep in $("${deps}"); do
        bee::resolve_plugin "${dep}"
        if [[ -n "${BEE_RESOLVE_PLUGIN_PATH}" ]]; then
          bee::load_plugin_deps
        else
          BEE_LOAD_PLUGIN_MISSING+=("${dep}")
        fi
      done
    fi
  fi
}

bee::run_plugin() {
  local plugin="$1"; shift
  if (($#)); then
    local cmd="$1"; shift
    "${plugin}::${cmd}" "$@"
  else
    "${plugin}::help"
  fi
}

################################################################################
# completion
################################################################################
declare -ig COMP_PARTIAL=1
bee::comp() {
  # complete -C bee bee
  # COMP_WORDBREAKS=${COMP_WORDBREAKS//:}
  # shellcheck disable=SC2207
  local words=($(bee::split_args "${COMP_LINE}"))
  local -i head=0 cursor=0
  for word in "${words[@]}"; do
    ((head += ${#word} + 1))
    ((head <= COMP_POINT)) && ((cursor+=1))
  done
  local cur="${words[cursor]:-}" wordlist
  ((cursor == ${#words[@]})) && COMP_PARTIAL=0
  if ((cursor == 1)); then # e.g. bee plu
    wordlist="$(bee::comp_modules && bee::comp_plugins)"
  else # e.g. bee hub inst
    wordlist="$(bee::comp_module_or_plugin "${words[1]}" "${words[@]:2}")"
  fi
  compgen -W "${wordlist}" -- "${cur}"
}

bee::comp_modules() {
  find "${BEE_MODULES_PATH}" -mindepth 1 -maxdepth 1 -type f -name "*.bash" ! -name "help.bash" -exec basename {} ".bash" \;
}

bee::comp_plugins() {
  # shellcheck disable=SC2015
  for plugins_path in "${BEE_PLUGINS_PATHS[@]}"; do
    [[ -d "${plugins_path}" ]] && find "${plugins_path}" -mindepth 1 -maxdepth 1 -type d -exec basename {} \; || true
  done
}

bee::comp_module_or_plugin() {
  bee::load_module "$1"
  if [[ -n "${BEE_LOAD_MODULE_NAME}" ]]; then
    shift
    local comp="bee::${BEE_LOAD_MODULE_NAME}::comp"
    [[ $(command -v "${comp}") == "${comp}" ]] && "${comp}" "$@"
    return
  fi

  bee::load_plugin "$1"
  if [[ -n "${BEE_LOAD_PLUGIN_NAME}" ]]; then
    shift
    local comp="${BEE_LOAD_PLUGIN_NAME}::comp"
    [[ $(command -v "${comp}") == "${comp}" ]] && "${comp}" "$@"
    return
  fi
}

################################################################################
# traps
################################################################################
declare -ig BEE_VERBOSE=0
declare -ig BEE_CANCELED=0
declare -ig BEE_MODE_INTERNAL=0
declare -ig BEE_MODE_PLUGIN=1
declare -ig BEE_MODE=${BEE_MODE_INTERNAL}
declare -ig T=${SECONDS}

declare -Ag BEE_TRAPS_INT=()
declare -Ag BEE_TRAPS_TERM=()
declare -Ag BEE_TRAPS_EXIT=()
bee::add_int_trap() { BEE_TRAPS_INT["$1"]="$1"; }
bee::add_term_trap() { BEE_TRAPS_TERM["$1"]="$1"; }
bee::add_exit_trap() { BEE_TRAPS_EXIT["$1"]="$1"; }
bee::remove_int_trap() { unset 'BEE_TRAPS_INT["$1"]'; }
bee::remove_term_trap() { unset 'BEE_TRAPS_TERM["$1"]'; }
bee::remove_exit_trap() { unset 'BEE_TRAPS_EXIT["$1"]'; }

bee::INT() { BEE_CANCELED=1; for t in "${BEE_TRAPS_INT[@]}"; do "$t"; done; }
bee::TERM() { BEE_CANCELED=1; for t in "${BEE_TRAPS_TERM[@]}"; do "$t"; done; }
bee::EXIT() {
  local -i status=$?
  for t in "${BEE_TRAPS_EXIT[@]}"; do "$t" ${status}; done
  if ((!BEE_QUIET && BEE_MODE == BEE_MODE_PLUGIN)); then
    local duration="$((SECONDS - T)) seconds"
    if ((BEE_CANCELED)); then
      bee::log_warn "bzzzz (${duration})"
    else
      if ((status)); then
        bee::log_error "bzzzz ${status} (${duration})"
      else
        bee::log "bzzzz (${duration})"
      fi
    fi
  fi
}

################################################################################
# run
################################################################################
bee::batch() {
  for batch in "$@"; do
    local cmd="${batch%% *}"
    local args="${batch#* }"
    if [[ "${args}" != "${cmd}" ]]; then
      # shellcheck disable=SC2046
      bee::run "${cmd}" $(bee::split_args "${args}")
    else
      bee::run "${cmd}"
    fi
  done
}

bee::split_args() {
  local IFS=" "
  # shellcheck disable=SC2068
  for arg in $@; do echo "${arg}"; done
}

bee::usage() {
  bee::load_module "help"
  bee::run_module "${BEE_LOAD_MODULE_NAME}"
}

bee::run() {
  if [[ -v COMP_LINE ]]; then
    bee::comp "$@"
    exit 0
  fi

  trap bee::INT INT
  trap bee::TERM TERM
  trap bee::EXIT EXIT

  # shellcheck disable=SC2034
  while (($#)); do case "$1" in
    -b | --batch) shift; bee::batch "$@"; return ;;
    -h | --help) bee::usage; return ;;
    -q | --quiet) BEE_QUIET=1; shift; ;;
    -v | --verbose) BEE_VERBOSE=1; shift; ;;
    --version) cat "${BEE_HOME}/version.txt"; return ;;
    --) shift; break ;; *) break ;;
  esac done

  if (($#)); then
    # run bee module, e.g. bee plugins ls
    bee::load_module "$1"
    if [[ -n "${BEE_LOAD_MODULE_NAME}" ]]; then
      shift
      bee::run_module "${BEE_LOAD_MODULE_NAME}" "$@"
      return
    fi
    # run bee plugin, e.g. bee github me
    bee::load_plugin "$1"
    if [[ -n "${BEE_LOAD_PLUGIN_NAME}" ]]; then
      BEE_MODE=${BEE_MODE_PLUGIN}
      shift
      bee::run_plugin "${BEE_LOAD_PLUGIN_NAME}" "$@"
      return
    fi
    # run args, e.g. bee echo "message"
    "$@"
  else
    bee::usage
  fi
}
