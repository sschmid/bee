# shellcheck disable=SC1090,SC2153,SC2178

################################################################################
# defaults
################################################################################

declare -r BEE_LATEST_VERSION_PATH="${BEE_LATEST_VERSION_PATH:-"https://raw.githubusercontent.com/sschmid/bee/main/version.txt"}"
declare -r BEE_WIKI="${BEE_WIKI:-"https://github.com/sschmid/bee/wiki"}"
declare -ir BEE_LATEST_VERSION_CACHE_EXPIRE="${BEE_LATEST_VERSION_CACHE_EXPIRE:-14400}" # 4h * 60 * 60
: "${BEE_HUB_PULL_COOLDOWN:=900}" # 15m * 60

BEE_HUBS_CACHE_PATH="${BEE_CACHE_PATH}/hubs"
if [[ -v BEE_PLUGINS_PATHS ]]
then BEE_PLUGINS_PATHS+=("${BEE_CACHE_PATH}/plugins")
else BEE_PLUGINS_PATHS=("${BEE_CACHE_PATH}/plugins")
fi

################################################################################
# helpers
################################################################################

bee::to_cache_path() {
  case "$1" in
    https://*) echo "$(dirname "${1#https://}")/$(basename "$1" .git)" ;;
    git://*) echo "$(dirname "${1#git://}")/$(basename "$1" .git)" ;;
    git@*) local path="${1#git@}"; echo "$(dirname "${path/://}")/$(basename "$1" .git)" ;;
    ssh://*) local path="${1#ssh://}"; echo "$(dirname "${path#git@}")/$(basename "$1" .git)" ;;
    file://*) basename "$1" ;;
    *) bee::log_warning "Unsupported url: $1" ;;
  esac
}

################################################################################
# plugins
################################################################################

bee::plugins::comp() {
  local comps=(--all --lock --outdated --version)
  while (( $# )); do
    case "$1" in
      --all) comps=("${comps[@]/--all/}"); shift ;;
      --lock) comps=("${comps[@]/--lock/}"); shift ;;
      --outdated) comps=("${comps[@]/--outdated/}"); shift ;;
      --version) comps=("${comps[@]/--version/}"); shift ;;
      --) shift; break ;; *) break ;;
    esac
  done
  compgen -W "${comps[*]}" -- "${1:-}"
}

bee::plugins() {
  local -i show_all=0
  local -i show_lock=0
  local -i show_outdated=0
  local -i show_version=0
  while (( $# )); do
    case "$1" in
      --all) show_all=1; shift ;;
      --lock) show_lock=1; shift ;;
      --outdated) show_outdated=1; shift ;;
      --version) show_version=1; shift ;;
      --) shift; break ;; *) break ;;
    esac
  done

  if (( $# )); then
    bee::source "bee-help"
    exit 1
  else
    local plugin_entry plugin_version
    local -a plugins found=() missing=()
    if (( show_all )); then
      mapfile -t plugins < <(bee::comp_plugins)
      plugins=("${BEE_PLUGINS[@]}" "${plugins[@]}")
    else
      plugins=("${BEE_PLUGINS[@]}")
    fi
    if (( show_lock )); then
      [[ -v BEE_FILE && -f "${BEE_FILE}.lock" ]] || return 1
      mapfile -t plugins < <(tr -d '└├│─' < "${BEE_FILE}.lock")
      mapfile -t plugins < <(echo "${plugins[*]// /}" | awk '!line[$0]++')
    fi
    for plugin in "${plugins[@]}"; do
      bee::mapped_plugin "${plugin}"
      if [[ -n "${BEE_RESOLVE_PLUGIN_FULL_PATH}" ]]; then
        plugin_entry="${BEE_RESOLVE_PLUGIN_NAME}"
        plugin_version="${BEE_RESOLVE_PLUGIN_VERSION}"
        (( show_version || show_lock || show_outdated )) && plugin_entry="${plugin_entry}:${plugin_version}"
        if (( show_lock )); then
          if [[ -z "${BEE_RESOLVE_PLUGIN_FULL_PATH}" ]]; then
            missing+=("${BEE_COLOR_FAIL}${BEE_CHECK_FAIL} ${plugin_entry}${BEE_COLOR_RESET}")
          fi
        elif (( show_outdated )); then
          bee::resolve_plugin "${BEE_RESOLVE_PLUGIN_NAME}"
          if [[ -n "${BEE_RESOLVE_PLUGIN_FULL_PATH}" && "${BEE_RESOLVE_PLUGIN_VERSION}" != "${plugin_version}" ]]; then
            found+=("${plugin_entry} ${BEE_RESULT} ${BEE_RESOLVE_PLUGIN_NAME}:${BEE_RESOLVE_PLUGIN_VERSION}")
          fi
        else
          found+=("${plugin_entry}")
        fi
      else
        missing+=("${BEE_COLOR_FAIL}${BEE_CHECK_FAIL} ${plugin}${BEE_COLOR_RESET}")
      fi
    done

    (( ${#found[@]} )) && echo "${found[*]}" | LC_ALL=C sort -u
    if (( ${#missing[@]} )); then
      echo -e "${missing[*]}" | LC_ALL=C sort -u
      return 1
    fi
  fi
}

bee::resolve() {
  local plugin="$1" plugins_path="$2" file="$3"
  local -i allow_local=${4:-0}
  local plugin_name="${plugin%:*}" plugin_version="${plugin##*:}" path
  path="${plugins_path}/${plugin_name}"
  if [[ ${allow_local} -eq 1 && -f "${path}/${file}" ]]; then
    echo -e "${plugin_name}\tlocal\t${path}\t1"
  else
    if [[ "${plugin_name}" == "${plugin_version}" && -d "${path}" ]]; then
      plugin_version="$(basename "$(find "${path}" -maxdepth 1 -mindepth 1 -type d | LC_ALL=C sort -rV | head -n 1)")"
    fi
    [[ ! -f "${path}/${plugin_version}/${file}" ]] || echo -e "${plugin_name}\t${plugin_version}\t${path}\t0"
  fi
}

BEE_RESOLVE_PLUGIN_NAME=""
BEE_RESOLVE_PLUGIN_VERSION=""
BEE_RESOLVE_PLUGIN_IS_LOCAL=""
BEE_RESOLVE_PLUGIN_BASE_PATH=""
BEE_RESOLVE_PLUGIN_FULL_PATH=""
BEE_RESOLVE_PLUGIN_JSON_PATH=""

bee::resolve_plugin() {
  local plugin="$1" plugin_name plugin_version plugin_path is_local
  local -i found=0
  for plugins_path in "${BEE_PLUGINS_PATHS[@]}"; do
    while read -r plugin_name plugin_version plugin_path is_local; do
      found=1
      BEE_RESOLVE_PLUGIN_NAME="${plugin_name}"
      BEE_RESOLVE_PLUGIN_VERSION="${plugin_version}"
      BEE_RESOLVE_PLUGIN_IS_LOCAL=${is_local}
      BEE_RESOLVE_PLUGIN_BASE_PATH="${plugin_path}"
      if (( BEE_RESOLVE_PLUGIN_IS_LOCAL )); then
        BEE_RESOLVE_PLUGIN_FULL_PATH="${BEE_RESOLVE_PLUGIN_BASE_PATH}/${BEE_RESOLVE_PLUGIN_NAME}.bash"
        BEE_RESOLVE_PLUGIN_JSON_PATH="${BEE_RESOLVE_PLUGIN_BASE_PATH}/plugin.json"
      else
        BEE_RESOLVE_PLUGIN_FULL_PATH="${BEE_RESOLVE_PLUGIN_BASE_PATH}/${BEE_RESOLVE_PLUGIN_VERSION}/${BEE_RESOLVE_PLUGIN_NAME}.bash"
        BEE_RESOLVE_PLUGIN_JSON_PATH="${BEE_RESOLVE_PLUGIN_BASE_PATH}/${BEE_RESOLVE_PLUGIN_VERSION}/plugin.json"
      fi
    done < <(bee::resolve "${plugin}" "${plugins_path}" "${plugin%:*}.bash" 1)
    (( found )) && break
  done
  if (( ! found )); then
    BEE_RESOLVE_PLUGIN_NAME=""
    BEE_RESOLVE_PLUGIN_VERSION=""
    BEE_RESOLVE_PLUGIN_IS_LOCAL=0
    BEE_RESOLVE_PLUGIN_BASE_PATH=""
    BEE_RESOLVE_PLUGIN_FULL_PATH=""
    BEE_RESOLVE_PLUGIN_JSON_PATH=""
  fi
}

BEE_LOAD_PLUGIN_NAME=""
BEE_LOAD_PLUGIN_PATH=""
BEE_LOAD_PLUGIN_JSON_PATH=""
declare -Ag BEE_LOAD_PLUGIN_LOADED=()
BEE_LOAD_PLUGIN_MISSING=()

bee::load_plugin() {
  local -i ignore_missing=${2:-0}
  BEE_LOAD_PLUGIN_MISSING=()
  bee::mapped_plugin "$1"
  if [[ -n "${BEE_RESOLVE_PLUGIN_FULL_PATH}" ]]; then
    BEE_LOAD_PLUGIN_NAME="${BEE_RESOLVE_PLUGIN_NAME}"
    BEE_LOAD_PLUGIN_PATH="${BEE_RESOLVE_PLUGIN_FULL_PATH}"
    BEE_LOAD_PLUGIN_JSON_PATH="${BEE_RESOLVE_PLUGIN_JSON_PATH}"
    bee::load_plugin_deps
    if [[ ${ignore_missing} -eq 0 && ${#BEE_LOAD_PLUGIN_MISSING[@]} -gt 0 ]]; then
      for missing in "${BEE_LOAD_PLUGIN_MISSING[@]}"; do
        bee::log_error "Missing plugin: '${missing}'"
      done
      return 1
    fi
  else
    BEE_LOAD_PLUGIN_NAME=""
    BEE_LOAD_PLUGIN_PATH=""
    BEE_LOAD_PLUGIN_JSON_PATH=""
  fi
}

bee::load_plugin_deps() {
  if [[ ! -v BEE_LOAD_PLUGIN_LOADED["${BEE_RESOLVE_PLUGIN_FULL_PATH}"] ]]; then
    bee::load_os "$(dirname "${BEE_RESOLVE_PLUGIN_FULL_PATH}")"
    source "${BEE_RESOLVE_PLUGIN_FULL_PATH}"
    BEE_LOAD_PLUGIN_LOADED["${BEE_RESOLVE_PLUGIN_FULL_PATH}"]=1
    if [[ -f "${BEE_RESOLVE_PLUGIN_JSON_PATH}" ]]; then
      for dep in $(jq -r '.dependencies[]?' "${BEE_RESOLVE_PLUGIN_JSON_PATH}"); do
        bee::mapped_plugin "${dep}"
        if [[ -n "${BEE_RESOLVE_PLUGIN_FULL_PATH}" ]]; then
          bee::load_plugin_deps
        else
          BEE_LOAD_PLUGIN_MISSING+=("${dep}")
        fi
      done
    fi
  fi
}

bee:map_bee_plugins() {
  [[ ! -v BEE_PLUGINS ]] || bee::map_plugins "${BEE_PLUGINS[@]}" >/dev/null
}

declare -Ag BEE_PLUGIN_MAP=()
declare -Ag BEE_PLUGIN_MAP_LOCK=()
declare -Ag BEE_PLUGIN_MAP_LATEST=()
declare -ag BEE_PLUGIN_MAP_CONFLICTS=()

bee::map_plugins() {
  bee::map_plugins_recursively "$@"
  if (( ${#BEE_PLUGIN_MAP_CONFLICTS[@]} )); then
    bee::log_warning "Version conflicts:" "${BEE_PLUGIN_MAP_CONFLICTS[*]}"
  fi
  for plugin_name in "${!BEE_PLUGIN_MAP_LATEST[@]}"; do
    if [[ -v BEE_PLUGIN_MAP_LOCK["${plugin_name}"] ]]
    then BEE_PLUGIN_MAP["${plugin_name}"]="${BEE_PLUGIN_MAP_LOCK["${plugin_name}"]}"
    else BEE_PLUGIN_MAP["${plugin_name}"]="${BEE_PLUGIN_MAP_LATEST["${plugin_name}"]}"
    fi
  done
  for plugin_name in "${!BEE_PLUGIN_MAP_LOCK[@]}"; do
    if [[ ! -v BEE_PLUGIN_MAP["${plugin_name}"] ]]; then
      BEE_PLUGIN_MAP["${plugin_name}"]="${BEE_PLUGIN_MAP_LOCK["${plugin_name}"]}"
    fi
  done
  for plugin_name in "${!BEE_PLUGIN_MAP[@]}"; do
    echo "${plugin_name}:${BEE_PLUGIN_MAP["${plugin_name}"]}"
  done
}

bee::map_plugins_recursively() {
  local plugin_name plugin_version
  local -a with_version=() without_version=()
  for plugin in "$@"; do
    if [[ "${plugin%:*}" == "${plugin##*:}" ]]
    then without_version+=("${plugin}")
    else with_version+=("${plugin}")
    fi
  done
  for plugin in "${with_version[@]}"; do
    plugin_name="${plugin%:*}"
    plugin_version="${plugin##*:}"
    [[ ! -v BEE_PLUGIN_MAP_LOCK["${plugin_name}"] || "${BEE_PLUGIN_MAP_LOCK["${plugin_name}"]}" != "${plugin_version}" ]] || continue
    [[ ! -v BEE_PLUGIN_MAP_LATEST["${plugin_name}"] || "${BEE_PLUGIN_MAP_LATEST["${plugin_name}"]}" != "${plugin_version}" ]] || continue
    bee::resolve_plugin "${plugin}"
    if [[ -n "${BEE_RESOLVE_PLUGIN_FULL_PATH}" ]]; then
      if [[ ! -v BEE_PLUGIN_MAP_LOCK["${BEE_RESOLVE_PLUGIN_NAME}"] ]]; then
        BEE_PLUGIN_MAP_LOCK["${BEE_RESOLVE_PLUGIN_NAME}"]="${BEE_RESOLVE_PLUGIN_VERSION}"
      else
        local locked_version="${BEE_PLUGIN_MAP_LOCK["${BEE_RESOLVE_PLUGIN_NAME}"]}"
        local resolved_version="${BEE_RESOLVE_PLUGIN_VERSION}"
        if [[ "${locked_version}" != "${resolved_version}" ]]; then
          BEE_PLUGIN_MAP_LOCK["${BEE_RESOLVE_PLUGIN_NAME}"]="$(echo -e "${locked_version}\n${resolved_version}" | sort -rV | head -n 1)"
          BEE_PLUGIN_MAP_CONFLICTS+=("${BEE_RESOLVE_PLUGIN_NAME}:${locked_version} <-> ${BEE_RESOLVE_PLUGIN_NAME}:${resolved_version}")
        fi
      fi
      bee::map_plugin_dependencies
    fi
  done
  for plugin in "${without_version[@]}"; do
    [[ ! -v BEE_PLUGIN_MAP_LATEST["${plugin}"] ]] || continue
    bee::resolve_plugin "${plugin}"
    if [[ -n "${BEE_RESOLVE_PLUGIN_FULL_PATH}" ]]; then
      if [[ ${BEE_RESOLVE_PLUGIN_IS_LOCAL} -eq 0 && ! -v BEE_PLUGIN_MAP_LATEST["${BEE_RESOLVE_PLUGIN_NAME}"] ]]; then
        BEE_PLUGIN_MAP_LATEST["${BEE_RESOLVE_PLUGIN_NAME}"]="${BEE_RESOLVE_PLUGIN_VERSION}"
      fi
      bee::map_plugin_dependencies
    fi
  done
}

bee::map_plugin_dependencies() {
  if [[ -f "${BEE_RESOLVE_PLUGIN_JSON_PATH}" ]]; then
    local deps
    deps="$(jq -r '.dependencies[]?' "${BEE_RESOLVE_PLUGIN_JSON_PATH}")"
    if [[ -n "${deps}" ]]; then
      # shellcheck disable=SC2086
      bee::map_plugins_recursively ${deps}
    fi
  fi
}

bee::mapped_plugin() {
  local plugin="$1"
  if [[ -v BEE_PLUGIN_MAP["${plugin}"] ]]
  then bee::resolve_plugin "${plugin}:${BEE_PLUGIN_MAP["${plugin}"]}"
  else bee::resolve_plugin "${plugin}"
  fi
}

bee::run_plugin() {
  local plugin="$1"; shift
  if (( $# )); then
    [[ $(command -v "bee::secrets") == "bee::secrets" ]] && bee::secrets "${plugin}" "$@"
    local cmd="$1"; shift
    "${plugin}::${cmd}" "$@"
  else
    "${plugin}::help"
  fi
}

################################################################################
# pull
################################################################################

bee::pull::comp() {
  if (( ! $# || $# == 1 && COMP_PARTIAL )); then
    local cmd="${1:-}" comps=(--force "${BEE_HUBS[*]}")
    compgen -W "${comps[*]}" -- "${cmd}"
  else
    echo "${BEE_HUBS[*]}"
  fi
}

bee::prompt() {
  [[ -v BEE_FILE ]] || return 1
  local current_version latest_version
  current_version=$(bee::source "bee-version")
  latest_version=$(bee::source "bee-version" --latest --cached)
  if [[ "${current_version}" == "${latest_version}" ]]
  then echo "${BEE_ICON} ${current_version}"
  else echo "${BEE_ICON} ${current_version}*"
  fi
}

bee::pull() {
  local -i force=0 pull=0
  while (( $# )); do
    case "$1" in
      --force) force=1; shift ;;
      --) shift; break ;; *) break ;;
    esac
  done

  mkdir -p "${BEE_HUBS_CACHE_PATH}"
  local cache_file="${BEE_HUBS_CACHE_PATH}/.bee_pull_cooldown"

  if (( force )); then
    pull=1
  else
    local -i now ts delta
    [[ ! -f "${cache_file}" ]] && echo "0" > "${cache_file}"
    now=$(date +%s)
    ts="$(cat "${cache_file}")"
    delta=$(( now - ts ))
    (( delta < BEE_HUB_PULL_COOLDOWN )) || pull=1
  fi

  if (( pull )); then
    local cache_path
    for url in "${@:-"${BEE_HUBS[@]}"}"; do
      cache_path="$(bee::to_cache_path "${url}")"
      if [[ -n "${cache_path}" ]]; then
        cache_path="${BEE_HUBS_CACHE_PATH}/${cache_path}"
        if [[ -d "${cache_path}" ]]; then
          pushd "${cache_path}" >/dev/null || exit 1
            git pull
          popd >/dev/null || exit 1
        else
          git clone "${url}" "${cache_path}" || true
        fi
      fi
    done
    date +%s > "${cache_file}"
  fi
}

################################################################################
# res
################################################################################

bee::res() {
  if (( ! $# )); then
    bee::source "bee-help"
    exit 1
  else
    local resources_dir target_dir
    for plugin in "$@" ; do
      bee::mapped_plugin "${plugin}"
      if [[ -n "${BEE_RESOLVE_PLUGIN_FULL_PATH}" ]]; then
        resources_dir="$(dirname "${BEE_RESOLVE_PLUGIN_FULL_PATH}")/resources"
        if [[ -d "${resources_dir}" ]]; then
          target_dir="${BEE_RESOURCES}/${BEE_RESOLVE_PLUGIN_NAME}"
          echo "Copying resources into ${target_dir}"
          mkdir -p "${target_dir}"
          cp -r "${resources_dir}/". "${target_dir}/"
        fi
      fi
    done
  fi
}

################################################################################
# update
################################################################################

bee::update::comp() {
  if (( ! $# || $# == 1 && COMP_PARTIAL )); then
    pushd "${BEE_SYSTEM_HOME}" >/dev/null || exit 1
      git branch -r --format '%(refname:short)' \
        | cut -d/ -f2- \
        | tail -n +2
    popd >/dev/null || exit 1
  fi
}

bee::update() {
  local branch="${1:-main}"
  pushd "${BEE_SYSTEM_HOME}" >/dev/null || exit 1
    git switch "${branch}"
    git pull
    bee::log "bee is up-to-date and ready to bzzzz"
  popd >/dev/null || exit 1
}

################################################################################
# traps
################################################################################

declare -ig BEE_VERBOSE=0
declare -ig BEE_CANCELED=0
declare -igr BEE_MODE_INTERNAL=0
declare -igr BEE_MODE_PLUGIN=1
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

bee::INT() {
  BEE_CANCELED=1
  for t in "${BEE_TRAPS_INT[@]}"; do
    "$t"
  done
}

bee::TERM() {
  BEE_CANCELED=1
  for t in "${BEE_TRAPS_TERM[@]}"; do
    "$t"
  done
}

bee::EXIT() {
  local -i status=$?
  for t in "${BEE_TRAPS_EXIT[@]}"; do "$t" ${status}; done
  if (( ! BEE_QUIET && BEE_MODE == BEE_MODE_PLUGIN )); then
    local duration="$(( SECONDS - T )) seconds"
    if (( BEE_CANCELED )); then
      bee::log_warning "bzzzz (${duration})"
    else
      if (( status )); then
        bee::log_error "bzzzz ${status} (${duration})"
      else
        bee::log "bzzzz (${duration})"
      fi
    fi
  fi
}

################################################################################
# completion
################################################################################

declare -ag BEE_OPTIONS=(--batch --help --quiet --verbose)
declare -ag BEE_COMMANDS=(cache env hash hubs info install job lint new plugins pull res update version wiki)

declare -i COMP_PARTIAL=1
# Add this to your .bashrc
# complete -C bee bee
bee::comp() {
  # shellcheck disable=SC2207
  local words=($(bee::split_args "${COMP_LINE}"))
  local -i head=0 cursor=0
  for word in "${words[@]}"; do
    (( head += ${#word} + 1 ))
    (( head <= COMP_POINT )) && (( cursor += 1 ))
  done
  local cur="${words[cursor]:-}" wordlist
  (( cursor == ${#words[@]} )) && COMP_PARTIAL=0
  if (( cursor == 1 )); then
    # e.g. bee
    local comps=("${BEE_OPTIONS[@]}" "${BEE_COMMANDS[@]}" "$(bee::comp_plugins)")
    wordlist="${comps[*]}"
  else
    # e.g. bee install
    wordlist="$(bee::comp_command_or_plugin "${words[1]}" "${words[@]:2}")"
  fi
  compgen -W "${wordlist}" -- "${cur}"
}

bee::comp_plugins() {
  compgen -A function |
    grep --color=never '^[a-zA-Z]*::[a-zA-Z]' |
    grep --color=never -v '^bee::' || true

  # shellcheck disable=SC2015
  for plugins_path in "${BEE_PLUGINS_PATHS[@]}"; do
    if [[ -d "${plugins_path}" ]]; then
      find "${plugins_path}" -maxdepth 1 -mindepth 1 -type d -exec basename {} \;
    fi
  done
}

bee::comp_plugin() {
  local plugin="$1"
  local -i n=$(( ${#plugin} + 3 ))
  compgen -A function |
    grep --color=never "^${plugin}::*" |
    cut -c $n- || true
}

bee::comp_command_or_plugin() {
  local comps=("${BEE_OPTIONS[@]}" "${BEE_COMMANDS[@]}" "$(bee::comp_plugins)")
  while (( $# )); do
    case "$1" in
      --batch) comps=("${comps[@]/--batch/--allow-fail}"); shift ;;
      --allow-fail) comps=("${comps[@]/--allow-fail/}"); shift ;;
      --help) return ;;
      --quiet) comps=("${comps[@]/--quiet/}"); shift ;;
      --verbose) comps=("${comps[@]/--verbose/}"); shift ;;
      *) break ;;
    esac
  done

  if (( $# )); then
    case "$1" in
      cache) shift; bee::source "bee-cache-comp" "$@"; return ;;
      env) shift; compgen -v; return ;;
      hubs) shift; bee::source "bee-hubs-comp" "$@"; return ;;
      info) shift; bee::source "bee-info-comp" "$@"; return ;;
      install) shift; bee::source "bee-install-comp" "$@"; return ;;
      job) shift; bee::source "bee-job-comp" "$@"; return ;;
      pull) shift; bee::pull::comp "$@"; return ;;
      plugins) shift; bee::plugins::comp "$@"; return ;;
      res) shift; bee::source "bee-hubs" --list; return ;;
      update) shift; bee::update::comp "$@"; return ;;
      version) shift; bee::source "bee-version-comp" "$@"; return ;;
    esac

    bee:map_bee_plugins
    bee::load_plugin "$1"
    if [[ -n "${BEE_LOAD_PLUGIN_NAME}" ]]; then
      shift
      local comp="${BEE_LOAD_PLUGIN_NAME}::comp"
      if [[ $(command -v "${comp}") == "${comp}" ]]; then
        "${comp}" "$@"
      elif (( ! $# || $# == 1 && COMP_PARTIAL )); then
        bee::comp_plugin "${BEE_LOAD_PLUGIN_NAME}"
      fi
      return
    fi

    compgen -W "${comps[*]}" -- "$1"
  else
    echo "${comps[*]}"
  fi
}

################################################################################
# run
################################################################################

bee::batch() {
  local -i allow_fail=0
  while (( $# )); do
    case "$1" in
      --allow-fail) allow_fail=1; shift ;;
      --) shift; break ;; *) break ;;
    esac
  done

  for batch in "$@"; do
    local cmd="${batch%% *}"
    local args="${batch#* }"
    if [[ "${args}" != "${cmd}" ]]; then
      # shellcheck disable=SC2046
      if (( allow_fail ))
      then bee::main "${cmd}" $(bee::split_args "${args}") || true
      else bee::main "${cmd}" $(bee::split_args "${args}")
      fi
    else
      if (( allow_fail ))
      then bee::main "${cmd}" || true
      else bee::main "${cmd}"
      fi
    fi
  done
}

bee::split_args() {
  local IFS=' '
  # shellcheck disable=SC2068
  for arg in $@; do echo "${arg}"; done
}

bee::source() {
  local cmd="$1"; shift
  # Run in subshell to avoid polluting the current shell
  # while still allowing the script to access variables and functions
  (source "${BEE_HOME}/src/${cmd}.bash" "$@")
}

bee::main() {
  if [[ -v COMP_LINE ]]; then
    bee::comp
    exit 0
  fi

  trap bee::INT INT
  trap bee::TERM TERM
  trap bee::EXIT EXIT

  while (( $# )); do
    case "$1" in
      --batch) shift; bee::batch "$@"; return ;;
      --help) bee::source "bee-help"; return ;;
      --quiet) BEE_QUIET=1; shift ;;
      --verbose)
        # shellcheck disable=SC2034
        BEE_VERBOSE=1; shift ;;
      --) shift; break ;; *) break ;;
    esac
  done

  if (( $# )); then
    case "$1" in
      cache) shift; bee::source "bee-cache" "$@"; return ;;
      env) shift; bee::env "$@"; return ;;
      hash) shift; bee::source "bee-hash" "$@"; return ;;
      hubs) shift; bee::source "bee-hubs" "$@"; return ;;
      info) shift; bee::source "bee-info" "$@"; return ;;
      install) shift; bee::source "bee-install" "$@"; return ;;
      job) shift; bee::source "bee-job" "$@"; return ;;
      lint) shift; bee::source "bee-lint" "$@"; return ;;
      new) shift; bee::source "bee-new" "$@"; return ;;
      plugins) shift; bee:map_bee_plugins; bee::plugins "$@"; return ;;
      prompt) shift; bee::prompt; return ;;
      pull) shift; bee::pull "$@"; return ;;
      res) shift; bee:map_bee_plugins; bee::res "$@"; return ;;
      update) shift; bee::update "$@"; return ;;
      version) shift; bee::source "bee-version" "$@"; return ;;
      wiki) shift; bee::source "bee-wiki" "$@"; return ;;
    esac

    # run bee plugin, e.g. bee github me
    bee:map_bee_plugins
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
    bee::source "bee-help"
    exit 1
  fi
}
