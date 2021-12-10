# shellcheck disable=SC1090,SC2153
: "${BEE_LATEST_VERSION_PATH:=https://raw.githubusercontent.com/sschmid/bee/main/version.txt}"
: "${BEE_WIKI:=https://github.com/sschmid/bee/wiki}"
: "${BEE_LATEST_VERSION_CACHE_EXPIRE:=14400}" # 4h * 60 * 60
: "${BEE_HUB_PULL_COOLDOWN:=900}" # 15m * 60

BEE_HUBS_CACHE_PATH="${BEE_CACHES_PATH}/hubs"
BEE_LINT_CACHE_PATH="${BEE_CACHES_PATH}/lint"
if [[ -v BEE_PLUGINS_PATHS ]]
then BEE_PLUGINS_PATHS+=("${BEE_CACHES_PATH}/plugins")
else BEE_PLUGINS_PATHS=("${BEE_CACHES_PATH}/plugins")
fi

bee::help() {
  cat << EOF

██████╗ ███████╗███████╗
██╔══██╗██╔════╝██╔════╝
██████╔╝█████╗  █████╗
██╔══██╗██╔══╝  ██╔══╝
██████╔╝███████╗███████╗
╚═════╝ ╚══════╝╚══════╝

${BEE_ICON} bee $(bee::version) - plugin-based bash automation

usage: bee [--help]
           [--quiet] [--verbose]
           [--batch] <command> [<args>]

  cache [--clear [<path>]]                   open (or --clear) cache
  env <vars>                                 print env variables
  hash <path>                                generate plugin hash
  hubs [--all | --list ] [<urls>]            list hubs and their plugins (--all versions as --list)
  info <plugin>                              print plugin spec
  install [--force] [<plugins>]              install plugins (--force ignore sha256 mismatch)
  job [--time] <title> <command>             run command as a job (show elapsed --time)
  lint <spec>                                validate plugin spec
  new [<path>]                               create new Beefile
  plugins [--all | --outdated] [--version]   list (--all or --outdated) plugins (with --version)
  pull [--force] [<urls>]                    update hubs (--force ignore pull cooldown)
  update                                     update bee to the latest version
  version [--print] [--cached]               print (--latest) version (--cached locally)
  wiki                                       open wiki

EOF
}

################################################################################
# cache
################################################################################
bee::cache::comp() {
  if ((!$# || $# == 1 && COMP_PARTIAL)); then
    local cmd="${1:-}" comps=(--clear)
    compgen -W "${comps[*]}" -- "${cmd}"
  elif (($# == 1 || $# == 2 && COMP_PARTIAL)); then
    if [[ -d "${BEE_CACHES_PATH}" ]]; then
      ls "${BEE_CACHES_PATH}"
    fi
  fi
}

bee::cache() {
  if (($#)); then
    case "$1" in
      --clear) rm -rf "${BEE_CACHES_PATH}${2:+/$2}" ;;
      *) bee::help ;;
    esac
  else
    os_open "${BEE_CACHES_PATH}"
  fi
}

################################################################################
# hash
################################################################################
BEE_HUB_HASH_RESULT=""
bee::hash() {
  if ((!$#)); then
    bee::help
  else
    local exclude=(git .DS_Store)
    # shellcheck disable=SC2207
    [[ -v BEE_HUB_HASH_EXCLUDE ]] && exclude+=($(bee::split_args "${BEE_HUB_HASH_EXCLUDE:-}"))
    local path="$1" file_hash all
    local -a hashes=()
    echo "$path"
    pushd "${path}" > /dev/null || exit 1
      local file
      while read -r file; do
        file_hash="$(os_sha256sum "${file}")"
        echo "${file_hash}"
        hashes+=("${file_hash// */}")
      done < <(find . -type f | grep -vFf <(echo "${exclude[*]}") | sort)
    popd > /dev/null || exit 1
    all="$(echo "${hashes[*]}" | os_sha256sum)"
    echo "${all}"
    BEE_HUB_HASH_RESULT="${all// */}"
  fi
}

################################################################################
# hubs
################################################################################
bee::hubs::comp() {
  if ((!$# || $# == 1 && COMP_PARTIAL)); then
    local cmd="${1:-}" comps=(--all --list "${BEE_HUBS[*]}")
    compgen -W "${comps[*]}" -- "${cmd}"
  else
    echo "${BEE_HUBS[*]}"
  fi
}

bee::hubs() {
  local -i show_all=0 list=0
  while (($#)); do case "$1" in
    --all) show_all=1; shift ;;
    --list) list=1; shift ;;
    --) shift; break ;; *) break ;;
  esac done

  if ((list)); then
    local cache_path
    for url in "${@:-"${BEE_HUBS[@]}"}"; do
      cache_path="$(bee::to_cache_path "${url}")"
      if [[ -n "$cache_path" ]]; then
        cache_path="${BEE_HUBS_CACHE_PATH}/${cache_path}"
        if [[ -d "${cache_path}" ]]; then
          ls "${cache_path}"
        fi
      fi
    done
  else
    local cache_path plugin_name plugin_version indent bullet
    local -a plugins versions
    local -i i j n m
    for url in "${@:-"${BEE_HUBS[@]}"}"; do
      cache_path="$(bee::to_cache_path "${url}")"
      if [[ -n "${cache_path}" ]]; then
        cache_path="${BEE_HUBS_CACHE_PATH}/${cache_path}"
        echo "${url}"
        if [[ -d "${cache_path}" ]]; then
          mapfile -t plugins < <(ls "${cache_path}")
          n=${#plugins[@]}
          for ((i = 0; i < n; i++)); do
            plugin_name="${plugins[i]}"
            ((i == n - 1)) && bullet="└── " || bullet="├── "
            echo "${bullet}${plugin_name}"

            if ((show_all)); then
              mapfile -t versions < <(find "${cache_path}/${plugin_name}" -mindepth 1 -maxdepth 1 -type d | sort -V)
              m=${#versions[@]}
              for ((j = 0; j < m; j++)); do
                plugin_version="$(basename "${versions[j]}")"
                ((i == n - 1)) && indent="    " || indent="│    "
                ((j == m - 1)) && bullet="└── " || bullet="├── "
                echo "${indent}${bullet}${plugin_version}"
              done
            fi
          done
          echo
        fi
      fi
    done
  fi
}

bee::to_cache_path() {
  case "$1" in
    https://*) echo "$(dirname "${1#https://}")/$(basename "$1" .git)" ;;
    git://*) echo "$(dirname "${1#git://}")/$(basename "$1" .git)" ;;
    git@*) local path="${1#git@}"; echo "$(dirname "${path/://}")/$(basename "$1" .git)" ;;
    ssh://*) local path="${1#ssh://}"; echo "$(dirname "${path#git@}")/$(basename "$1" .git)" ;;
    file://*) basename "$1" ;;
    *) bee::log_warn "Unsupported hub url: $1" ;;
  esac
}

################################################################################
# info
################################################################################
bee::info::comp() {
  if ((!$# || $# == 1 && COMP_PARTIAL)); then
    bee::hubs --list
  fi
}

bee::info() {
  if ((!$#)); then
    bee::help
  else
    local plugin="$1" plugin_name plugin_version cache_path spec_path
    local -i found=0
    for url in "${BEE_HUBS[@]}"; do
      cache_path="${BEE_HUBS_CACHE_PATH}/$(bee::to_cache_path "${url}")"
      while read -r plugin_name plugin_version spec_path; do
        found=1
        jq . "${spec_path}" || cat "${spec_path}"
      done < <(bee::resolve "${plugin}" "${cache_path}" "plugin.json")
      ((found)) && break
    done
  fi
}

################################################################################
# install
################################################################################
bee::install::comp() {
  local plugins
  plugins="$(bee::hubs --list)"
  if ((!$# || $# == 1 && COMP_PARTIAL)); then
    local cmd="${1:-}" comps=(--force "${plugins}")
    compgen -W "${comps[*]}" -- "${cmd}"
  else
    echo "${plugins}"
  fi
}

bee::install() {
  local -i force=0
  while (($#)); do case "$1" in
    --force) force=1; shift ;;
    --) shift; break ;; *) break ;;
  esac done
  echo "Installing"
  bee::install::recursively ${force} "" "$@"
}

bee::install::recursively() {
  local -i force="$1";
  local indent="$2";
  shift 2
  local -a plugins=("$@") missing=()
  local plugin plugin_name plugin_version cache_path spec_path bullet
  local -i i n=${#plugins[@]} found=0 already_installed=0
  for ((i = 0; i < n; i++)); do
    found=0
    plugin="${plugins[i]}"
    ((i == n - 1)) && bullet="└── " || bullet="├── "
    for url in "${BEE_HUBS[@]}"; do
      cache_path="${BEE_HUBS_CACHE_PATH}/$(bee::to_cache_path "${url}")"
      while read -r plugin_name plugin_version spec_path; do
        found=1
        local plugin_path="${BEE_CACHES_PATH}/plugins/${plugin_name}/${plugin_version}"
        local git tag sha deps
        while read -r git tag sha deps; do
          if [[ -d "${plugin_path}" ]]; then
            already_installed=1
          else
            already_installed=0
            git -c advice.detachedHead=false clone -q --depth 1 --branch "${tag}" "${git}" "${plugin_path}" || true
          fi
          if [[ -d "${plugin_path}" ]]; then
            bee::hash "${plugin_path}" > /dev/null
            if [[ "${BEE_HUB_HASH_RESULT}" != "${sha}" ]]; then
              if ((force)); then
                bee::log_warn "${plugin_name}:${plugin_version} sha256 mismatch!" \
                  "Plugin was tampered with or version has been modified. Authenticity is not guaranteed." \
                  "Consider deleting ${plugin_path} and run 'bee hub install ${plugin_name}:${plugin_version}'."
                echo -e "${indent}${bullet}${BEE_COLOR_WARN}${BEE_CHECK_SUCCESS} ${plugin_name}:${plugin_version} (${url})${BEE_COLOR_RESET}"
              else
                bee::log_error "${plugin_name}:${plugin_version} sha256 mismatch!" "Deleting ${plugin_path}" \
                  "Use 'bee hub info ${plugin_name}:${plugin_version}' to inspect the plugin definition." \
                  "Use 'bee hub install --force ${plugin_name}:${plugin_version}' to install anyway and proceed at your own risk."
                rm -rf "${plugin_path}"
                echo -e "${indent}${bullet}${BEE_COLOR_FAIL}${BEE_CHECK_FAIL} ${plugin_name}:${plugin_version} (${url})${BEE_COLOR_RESET}"
              fi
            else
              if ((already_installed)); then
                echo -e "${indent}${bullet}${plugin_name}:${plugin_version} (${url})"
              else
                echo -e "${indent}${bullet}${BEE_COLOR_SUCCESS}${BEE_CHECK_SUCCESS} ${plugin_name}:${plugin_version} (${url})${BEE_COLOR_RESET}"
              fi
            fi
          else
            echo -e "${indent}${bullet}${BEE_COLOR_FAIL}${BEE_CHECK_FAIL} ${plugin_name}:${plugin_version} (${url})${BEE_COLOR_RESET}"
          fi
          # shellcheck disable=SC2086
          if [[ -n "${deps}" ]]; then
            if ((i == n - 1)); then
              bee::install::recursively ${force} "${indent}    " ${deps}
            else
              bee::install::recursively ${force} "${indent}│   " ${deps}
            fi
          fi
        done < <(jq -r '[.git, .tag, .sha256, .dependencies[]?] | @tsv' "${spec_path}")
      done < <(bee::resolve "${plugin}" "${cache_path}" "plugin.json")
      ((found)) && break
    done
    if ((!found)); then
      missing+=("${plugin}")
      echo -e "${indent}${bullet}${BEE_COLOR_FAIL}${BEE_CHECK_FAIL} ${plugin}${BEE_COLOR_RESET}"
    fi
  done
  if ((${#missing[@]})); then
    for m in "${missing[@]}"; do
      bee::log_error "Couldn't install plugin: ${m}"
    done
    exit 1
  fi
}

################################################################################
# job
################################################################################
BEE_JOB_SPINNER_INTERVAL=0.1
BEE_JOB_SPINNER_FRAMES=('🐝' ' 🐝' '  🐝' '   🐝' '    🐝' '     🐝' '      🐝' '       🐝' '        🐝' '         🐝' '        🐝' '       🐝' '      🐝' '     🐝' '    🐝' '   🐝' '  🐝' ' 🐝' '🐝')
declare -ig BEE_JOB_SPINNER_PID=0
declare -ig BEE_JOB_RUNNING=0
declare -ig BEE_JOB_T=0
declare -ig BEE_JOB_SHOW_TIME=0
BEE_JOB_TITLE=""
BEE_JOB_LOGFILE=""

bee::job::comp() {
  if ((!$# || $# == 1 && COMP_PARTIAL)); then
    local cmd="${1:-}" comps=(--time)
    compgen -W "${comps[*]}" -- "${cmd}"
  fi
}

bee::job() {
  if (($# >= 2)); then
    while (($#)); do
      case "$1" in
        --time) BEE_JOB_SHOW_TIME=1; shift ;;
        --) shift; break ;; *) break ;;
      esac
    done

    bee::job::start "$@"
    bee::job::finish
  else
    bee::help
  fi
}

bee::job::start() {
  BEE_JOB_TITLE="$1"; shift
  if [[ -v BEE_RESOURCES ]]; then
    mkdir -p "${BEE_RESOURCES}/logs"
    BEE_JOB_LOGFILE="${BEE_RESOURCES}/logs/$(date -u '+%Y%m%d%H%M%S')-job-${BEE_JOB_TITLE// /-}-${RANDOM}${RANDOM}.log"
  else
    BEE_JOB_LOGFILE=/dev/null
  fi

  if ((BEE_VERBOSE)); then
    echo "${BEE_JOB_TITLE}"
    bee::run "$@" 2>&1 | tee "${BEE_JOB_LOGFILE}"
  else
    bee::job::start_spinner
    bee::run "$@" &> "${BEE_JOB_LOGFILE}"
  fi
}

bee::job::finish() {
  bee::job::stop_spinner
  local line_reset
  ((!BEE_VERBOSE)) && line_reset="${BEE_LINE_RESET}" || line_reset=""
  echo -e "${line_reset}${BEE_COLOR_SUCCESS}${BEE_JOB_TITLE} ${BEE_CHECK_SUCCESS}$(bee::job::duration)${BEE_COLOR_RESET}"
}

bee::job::start_spinner() {
  BEE_JOB_RUNNING=1
  BEE_JOB_T=${SECONDS}
  bee::add_int_trap bee::job::INT
  bee::add_exit_trap bee::job::EXIT
  if [[ -t 1 ]]; then
    tput civis &> /dev/null || true
    stty -echo
    bee::job::spin &
    BEE_JOB_SPINNER_PID=$!
  fi
}

bee::job::stop_spinner() {
  bee::remove_int_trap bee::job::INT
  bee::remove_exit_trap bee::job::EXIT
  if [[ -t 1 ]]; then
    if ((BEE_JOB_SPINNER_PID != 0)); then
      kill -9 ${BEE_JOB_SPINNER_PID} || true
      wait ${BEE_JOB_SPINNER_PID} &> /dev/null || true
      BEE_JOB_SPINNER_PID=0
    fi
    stty echo
    tput cnorm &> /dev/null || true
  fi
  BEE_JOB_RUNNING=0
}

bee::job::spin() {
  while true; do
    for i in "${BEE_JOB_SPINNER_FRAMES[@]}"; do
      echo -ne "${BEE_LINE_RESET}${BEE_JOB_TITLE}$(bee::job::duration) ${i}"
      sleep ${BEE_JOB_SPINNER_INTERVAL}
    done
  done
}

bee::job::INT() {
  ((!BEE_JOB_RUNNING)) && return
  bee::job::stop_spinner
  echo "Aborted by $(whoami)$(bee::job::duration)" >> "${BEE_JOB_LOGFILE}"
}

bee::job::EXIT() {
  local -i status=$1
  ((!BEE_JOB_RUNNING)) && return
  if ((status)); then
    bee::job::stop_spinner
    echo -e "${BEE_LINE_RESET}${BEE_COLOR_FAIL}${BEE_JOB_TITLE} ${BEE_CHECK_FAIL}$(bee::job::duration)${BEE_COLOR_RESET}"
  fi
}

bee::job::duration() { ((!BEE_JOB_SHOW_TIME)) || echo " ($((SECONDS - BEE_JOB_T)) seconds)"; }

################################################################################
# lint
################################################################################
bee::lint() {
  if ((!$#)); then
    bee::help
  else
    local spec_path="$1" key actual expected cache_path plugin_name git_url git_tag sha256_hash
    local -a plugin_deps

    key="name"
    plugin_name="$(jq -rc --arg key "${key}" '.[$key]' "${spec_path}")"
    expected="$(basename "$(dirname "$(dirname "${spec_path}")")")"
    bee::lint::assert_equal "${key}" "${plugin_name}" "${expected}"

    key="version"
    actual="$(jq -rc --arg key "${key}" '.[$key]' "${spec_path}")"
    expected="$(basename "$(dirname "${spec_path}")")"
    bee::lint::assert_equal "${key}" "${actual}" "${expected}"

    key="license"
    actual="$(jq -rc --arg key "${key}" '.[$key]' "${spec_path}")"
    bee::lint::assert_exist "${key}" "${actual}"

    key="homepage"
    actual="$(jq -rc --arg key "${key}" '.[$key]' "${spec_path}")"
    bee::lint::assert_exist "${key}" "${actual}"

    key="authors"
    actual="$(jq -rc --arg key "${key}" '.[$key]' "${spec_path}")"
    bee::lint::assert_exist "${key}" "${actual}"

    key="info"
    actual="$(jq -rc --arg key "${key}" '.[$key]' "${spec_path}")"
    bee::lint::assert_exist "${key}" "${actual}"

    key="git"
    git_url="$(jq -rc --arg key "${key}" '.[$key]' "${spec_path}")"
    bee::lint::assert_exist "${key}" "${git_url}"

    key="tag"
    git_tag="$(jq -rc --arg key "${key}" '.[$key]' "${spec_path}")"
    bee::lint::assert_exist "${key}" "${git_tag}"

    key="sha256"
    sha256_hash="$(jq -rc --arg key "${key}" '.[$key]' "${spec_path}")"
    bee::lint::assert_exist "${key}" "${sha256_hash}"

    key="dependencies"
    plugin_deps=("$(jq -rc --arg key "${key}" '.[$key][]? // null' "${spec_path}")")
    bee::lint::optional "${key}" "${plugin_deps[@]}"

    cache_path="$(bee::to_cache_path "${git_url}")"
    if [[ -n "${cache_path}" ]]; then
      cache_path="${BEE_LINT_CACHE_PATH}/${cache_path}"
      if [[ -d "${cache_path}" ]]; then
        pushd "${cache_path}" > /dev/null || exit 1
          bee::job "git fetch" git fetch
        popd > /dev/null || exit 1
      else
        bee::job "git clone" git clone "${git_url}" "${cache_path}"
      fi
    fi

    if [[ -n "${cache_path}" && -d "${cache_path}" ]]; then
      pushd "${cache_path}" > /dev/null || exit 1
        bee::job "git checkout tag" git checkout -q "${git_tag}"

        key="version file"
        local version_file="version.txt"
        if [[ -f "${version_file}" ]]; then
          actual="$(cat "${version_file}")"
          expected="$(basename "$(dirname "${spec_path}")")"
          bee::lint::assert_equal "${key}" "${actual}" "${expected}"
        else
          version_file="null"
          bee::lint::assert_exist "${key}" "${version_file}"
        fi

        key="license file"
        local license_file="LICENSE.txt"
        [[ ! -f "${license_file}" ]] && license_file="null"
        bee::lint::assert_exist "${key}" "${license_file}"

        key="sha256"
        bee::hash "${PWD}"
        bee::lint::assert_equal "${key}" "${sha256_hash}" "${BEE_HUB_HASH_RESULT}"

        key="plugin file"
        local plugin_file="${plugin_name}.bash"
        if [[ ! -f "${plugin_file}" ]]; then
          plugin_file="null"
          bee::lint::assert_exist "${key}" "${plugin_file}"
        else
          bee::lint::assert_exist "${key}" "${plugin_file}"

          key="dependencies"
          local deps=("$(
            source "${plugin_file}" > /dev/null
            local deps_func="${plugin_name}::deps"
            if [[ $(command -v "${deps_func}") == "${deps_func}" ]]; then
              "${deps_func}"
            else
              echo "null"
            fi
          )")
          bee::lint::assert_equal "${key}" \
            "$(echo "${plugin_deps[@]}" | tr '\n' ' ')" \
            "$(echo "${deps[@]}" | tr '\n' ' ')"
        fi
      popd > /dev/null || exit 1
    fi

    if ((BEE_HUB_LINT_ERROR)); then
      exit 1
    fi
  fi
}

declare -ig BEE_HUB_LINT_ERROR=0
bee::lint::assert_equal() {
  local key="$1" actual="$2" expected="$3"
  if [[ "${actual}" == "${expected}" ]]; then
    printf '%-22b%b\n' "${BEE_COLOR_SUCCESS}${key}" "${BEE_CHECK_SUCCESS} ${actual}${BEE_COLOR_RESET}"
  else
    printf '%-22b%b\n' "${BEE_COLOR_FAIL}${key}" "${BEE_CHECK_FAIL} ${actual} (must be ${expected})${BEE_COLOR_RESET}"
    BEE_HUB_LINT_ERROR=1
  fi
}

bee::lint::assert_exist() {
  local key="$1" actual="$2"
  if [[ "${actual}" != "null" ]]; then
    printf '%-22b%b\n' "${BEE_COLOR_SUCCESS}${key}" "${BEE_CHECK_SUCCESS} ${actual}${BEE_COLOR_RESET}"
  else
    printf '%-22b%b\n' "${BEE_COLOR_FAIL}${key}" "${BEE_CHECK_FAIL} ${actual} (required)${BEE_COLOR_RESET}"
    BEE_HUB_LINT_ERROR=1
  fi
}

bee::lint::optional() {
  local key="$1" actual="$2"
  if [[ "${actual}" != "null" ]]
  then printf '%-24b%b\n' "${BEE_COLOR_SUCCESS}${key}" "${BEE_CHECK_SUCCESS} ${actual}${BEE_COLOR_RESET}"
  else printf '%-24b%b\n' "${BEE_COLOR_WARN}${key}" "${actual}${BEE_COLOR_RESET}"
  fi
}

################################################################################
# new
################################################################################
bee::new() {
  local beefile="${1:-Beefile}"
  if [[ -f "${beefile}" ]]; then
    bee::log_error "${beefile} already exists"
    exit 1
  else
    cat << EOF > "${beefile}"
BEE_PROJECT=$(basename "${PWD}")
BEE_VERSION=$(bee::version)
BEE_RESOURCES=.bee

# Which plugins would you like to load?
# Standard plugins can be found in the official bee plugin register: https://github.com/sschmid/beehub
# More registers (and private registers) can be added by customizing ~/.beerc
#   BEE_HUBS=(
#     https://github.com/sschmid/beehub.git
#     https://github.com/my/beehub.git
#   )
#
# Custom local plugins may be added by customizing ~/.beerc
#   BEE_PLUGINS_PATHS=("${HOME}/path/to/my/plugins")
#
# Example format: BEE_PLUGINS=(changelog github:2.0.0 slack:1.0.0 version)
# You can specify a plugin version like this: plugin:x.y.z,
# otherwise the latest plugin version will be used
BEE_PLUGINS=(
  # android
  # changelog
  # github
  # ios
  # macos
  # sample
  # slack
  # tree
  # unity
  # version
)
EOF
    bee::log_echo "Created ${beefile}"
  fi
}

################################################################################
# plugins
################################################################################
bee::plugins::comp() {
  local comps=(--all --outdated --version)
  while (($#)); do case "$1" in
    --all) comps=("${comps[@]/--all}"); shift ;;
    --outdated) comps=("${comps[@]/--outdated}"); shift ;;
    --version) comps=("${comps[@]/--version}"); shift ;;
    --) shift; break ;; *) break ;;
  esac done
  compgen -W "${comps[*]}" -- "${1:-}"
}

bee::plugins() {
  local -i show_all=0
  local -i show_version=0
  local -i show_outdated=0
  while (($#)); do case "$1" in
    --all) show_all=1; shift ;;
    --outdated) show_outdated=1; shift ;;
    --version) show_version=1; shift ;;
    --) shift; break ;; *) break ;;
  esac done

  if (($#)); then
    bee::help
  else
    local plugin_entry plugin_version
    local -a plugins
    if ((show_all)); then
      mapfile -t plugins < <(bee::comp_plugins)
      plugins=("${BEE_PLUGINS[@]}" "${plugins[@]}")
    else
      plugins=("${BEE_PLUGINS[@]}")
    fi
    for plugin in "${plugins[@]}"; do
      bee::resolve_plugin "${plugin}"
      if [[ -n "${BEE_RESOLVE_PLUGIN_PATH}" ]]; then
        plugin_entry="${BEE_RESOLVE_PLUGIN_NAME}"
        plugin_version="${BEE_RESOLVE_PLUGIN_VERSION}"
        ((show_version || show_outdated)) && plugin_entry="${plugin_entry}:${plugin_version}"
        if ((show_outdated)); then
          bee::resolve_plugin "${BEE_RESOLVE_PLUGIN_NAME}"
          if [[ -n "${BEE_RESOLVE_PLUGIN_PATH}" && "${BEE_RESOLVE_PLUGIN_VERSION}" != "${plugin_version}" ]]; then
            echo "${plugin_entry} ${BEE_RESULT} ${BEE_RESOLVE_PLUGIN_NAME}:${BEE_RESOLVE_PLUGIN_VERSION}"
          fi
        else
          echo "${plugin_entry}"
        fi
      else
        echo -e "${BEE_COLOR_FAIL}${BEE_CHECK_FAIL} ${plugin}${BEE_COLOR_RESET}"
      fi
    done | sort -u
  fi
}

bee::resolve() {
  local plugin="$1" plugins_path="$2" file="$3"
  local plugin_name="${plugin%:*}" plugin_version="${plugin##*:}" path
  if [[ "${plugin_name}" == "${plugin_version}" && -d "${plugins_path}/${plugin_name}" ]]; then
    plugin_version="$(basename "$(find "${plugins_path}/${plugin_name}" -mindepth 1 -maxdepth 1 -type d | sort -rV | head -n 1)")"
  fi
  path="${plugins_path}/${plugin_name}/${plugin_version}/${file}"
  if [[ -f "${path}" ]]; then
    echo -e "${plugin_name}\t${plugin_version}\t${path}"
  fi
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
        found=1
        BEE_RESOLVE_PLUGIN_NAME="${plugin_name}" BEE_RESOLVE_PLUGIN_VERSION="${plugin_version}" BEE_RESOLVE_PLUGIN_PATH="${plugin_path}"
        BEE_RESOLVE_PLUGIN_PATH_CACHE["${BEE_RESOLVE_PLUGIN_NAME}:${BEE_RESOLVE_PLUGIN_VERSION}"]="${BEE_RESOLVE_PLUGIN_PATH}"
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
    local deps_func="${BEE_RESOLVE_PLUGIN_NAME}::deps"
    if [[ $(command -v "${deps_func}") == "${deps_func}" ]]; then
      for dep in $("${deps_func}"); do
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
# pull
################################################################################
bee::pull::comp() {
  if ((!$# || $# == 1 && COMP_PARTIAL)); then
    local cmd="${1:-}" comps=(--force "${BEE_HUBS[*]}")
    compgen -W "${comps[*]}" -- "${cmd}"
  else
    echo "${BEE_HUBS[*]}"
  fi
}

bee::pull() {
  local -i force=0 pull=0
  while (($#)); do case "$1" in
    --force) force=1; shift ;;
    --) shift; break ;; *) break ;;
  esac done

  mkdir -p "${BEE_HUBS_CACHE_PATH}"
  local cache_file="${BEE_HUBS_CACHE_PATH}/.bee_pull_cooldown"

  if ((force)); then
    pull=1
  else
    local -i now ts delta
    [[ ! -f "${cache_file}" ]] && echo "0" > "${cache_file}"
    now=$(date +%s)
    ts="$(cat "${cache_file}")"
    delta=$((now - ts))
    ((delta > BEE_HUB_PULL_COOLDOWN)) && pull=1
  fi

  if ((pull)); then
    local cache_path
    for url in "${@:-"${BEE_HUBS[@]}"}"; do
      cache_path="$(bee::to_cache_path "${url}")"
      if [[ -n "${cache_path}" ]]; then
        cache_path="${BEE_HUBS_CACHE_PATH}/${cache_path}"
        if [[ -d "${cache_path}" ]]; then
          pushd "${cache_path}" > /dev/null || exit 1
            git pull
          popd > /dev/null || exit 1
        else
          git clone "${url}" "${cache_path}" || true
        fi
      fi
    done
    date +%s > "${cache_file}"
  fi
}

################################################################################
# update
################################################################################
bee::update() {
  if (($#)); then
    bee::help
  else
    pushd "${BEE_SYSTEM_HOME}" > /dev/null || exit 1
      git pull origin main
      bee::log "bee is up-to-date and ready to bzzzz"
    popd > /dev/null || exit 1
  fi
}

################################################################################
# version
################################################################################
bee::version::comp() {
  local cmd="${1:-}"
  if ((!$# || $# == 1 && COMP_PARTIAL)); then
    local comps=(--latest)
    compgen -W "${comps[*]}" -- "${cmd}"
  elif (($# == 1 || $# == 2 && COMP_PARTIAL)); then
    case "${cmd}" in
      --latest) echo "--cached" ;;
    esac
  fi
}

bee::version() {
  local -i latest=0 cached=0
  while (($#)); do case "$1" in
    --latest) latest=1; shift ;;
    --cached) cached=1; shift ;;
    --) shift; break ;; *) break ;;
  esac done

  if (($#)); then
    bee::help
  elif ((latest)); then
    if ((cached)); then
      mkdir -p "${BEE_CACHES_PATH}"
      local -i last_ts now delta
      local cache cache_file="${BEE_CACHES_PATH}/.bee_latest_version_cache"
      [[ ! -f "${cache_file}" ]] && echo "0,0" > "${cache_file}"
      now=$(date +%s)
      cache="$(cat "${cache_file}")"
      last_ts="${cache%%,*}"
      delta=$((now - last_ts))
      if ((delta > BEE_LATEST_VERSION_CACHE_EXPIRE)); then
        local version
        version="$(curl -fsSL "${BEE_LATEST_VERSION_PATH}")"
        echo "${now},${version}" > "${cache_file}"
        echo "${version}"
      else
        echo "${cache##*,}"
      fi
    else
      curl -fsSL "${BEE_LATEST_VERSION_PATH}"
    fi
  else
    cat "${BEE_HOME}/version.txt"
  fi
}

################################################################################
# wiki
################################################################################
bee::wiki() {
  if (($#)); then
    bee::help
  else
    os_open "${BEE_WIKI}"
  fi
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
# completion
################################################################################
declare -ag BEE_COMMANDS=(
  --batch --help --quiet --verbose
  cache env hash hubs info install job lint new plugins pull update version wiki
)

declare -ig COMP_PARTIAL=1
# Add this to your .bashrc
# complete -C bee bee
# COMP_WORDBREAKS=${COMP_WORDBREAKS//:}
bee::comp() {
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
    wordlist="${BEE_COMMANDS[*]} $(bee::comp_plugins)"
  else # e.g. bee install ver
    wordlist="$(bee::comp_command_or_plugin "${words[1]}" "${words[@]:2}")"
  fi
  compgen -W "${wordlist}" -- "${cur}"
}

bee::comp_plugins() {
  # shellcheck disable=SC2015
  for plugins_path in "${BEE_PLUGINS_PATHS[@]}"; do
    if [[ -d "${plugins_path}" ]]; then
      find "${plugins_path}" -mindepth 1 -maxdepth 1 -type d -exec basename {} \;
    fi
  done
}

bee::comp_command_or_plugin() {
  case "$1" in
    cache) shift; bee::cache::comp "$@"; return ;;
    env) shift; compgen -v; return ;;
    hubs) shift; bee::hubs::comp "$@"; return ;;
    info) shift; bee::info::comp "$@"; return ;;
    install) shift; bee::install::comp "$@"; return ;;
    job) shift; bee::job::comp "$@"; return ;;
    pull) shift; bee::pull::comp "$@"; return ;;
    plugins) shift; bee::plugins::comp "$@"; return ;;
    update) return ;;
    version) shift; bee::version::comp "$@"; return ;;
  esac

  bee::load_plugin "$1"
  if [[ -n "${BEE_LOAD_PLUGIN_NAME}" ]]; then
    shift
    local comp="${BEE_LOAD_PLUGIN_NAME}::comp"
    if [[ $(command -v "${comp}") == "${comp}" ]]; then
      "${comp}" "$@"
    elif ((!$# || $# == 1 && COMP_PARTIAL)); then
      local -i n=$((${#BEE_LOAD_PLUGIN_NAME} + 3))
      compgen -A function \
        | grep --color=never "^${BEE_LOAD_PLUGIN_NAME}::*" \
        | cut -c $n- \
        || true
    fi
    return
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
  local IFS=' '
  # shellcheck disable=SC2068
  for arg in $@; do echo "${arg}"; done
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
    --batch) shift; bee::batch "$@"; return ;;
    --help) bee::help; return ;;
    --quiet) BEE_QUIET=1; shift; ;;
    --verbose) BEE_VERBOSE=1; shift; ;;
    --) shift; break ;; *) break ;;
  esac done

  if (($#)); then
    case "$1" in
      cache) shift; bee::cache "$@"; return ;;
      env) shift; bee::env "$@"; return ;;
      hash) shift; bee::hash "$@"; return ;;
      hubs) shift; bee::hubs "$@"; return ;;
      info) shift; bee::info "$@"; return ;;
      install) shift; bee::install "$@"; return ;;
      job) shift; bee::job "$@"; return ;;
      lint) shift; bee::lint "$@"; return ;;
      new) shift; bee::new "$@"; return ;;
      plugins) shift; bee::plugins "$@"; return ;;
      pull) shift; bee::pull "$@"; return ;;
      update) shift; bee::update "$@"; return ;;
      version) shift; bee::version "$@"; return ;;
      wiki) shift; bee::wiki "$@"; return ;;
    esac

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
    bee::help
  fi
}
