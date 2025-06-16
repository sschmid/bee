########################################
# Install plugins
# Arguments:
#   [--force] [plugin ...]
########################################
declare -Ag install_hashes=()

bee::install::recursively() {
  local -i force="$1" lock="$2"
  local indent="$3"
  shift 3
  local -a plugins=("$@") missing=()
  local plugin plugin_name plugin_version cache_path spec_path is_local bullet hash
  local -i i n=${#plugins[@]} found=0 already_installed=0
  for (( i = 0; i < n; i++ )); do
    found=0
    plugin="${plugins[i]// /}"
    (( i == n - 1 )) && bullet="└── " || bullet="├── "
    for url in "${BEE_HUBS[@]}"; do
      cache_path="${BEE_HUBS_CACHE_PATH}/$(bee::to_cache_path "${url}")"
      # shellcheck disable=SC2034
      while read -r plugin_name plugin_version spec_path is_local; do
        found=1
        spec_path="${spec_path}/${plugin_version}/plugin.json"
        local plugin_path="${BEE_CACHE_PATH}/plugins/${plugin_name}/${plugin_version}"
        local git tag sha deps
        while read -r git tag sha deps; do
          (( lock )) && echo "${indent}${bullet}${plugin_name}:${plugin_version}" >> "${BEE_FILE}.lock"
          if [[ -d "${plugin_path}" ]]; then
            already_installed=1
          else
            already_installed=0
            git -c advice.detachedHead=false clone -q --depth 1 --branch "${tag}" "${git}" "${plugin_path}" || true
          fi
          if [[ -d "${plugin_path}" ]]; then
            if [[ -v install_hashes["${plugin_path}"] ]]; then
              hash="${install_hashes["${plugin_path}"]}"
            else
              hash="$(bee::source "bee-hash" "${plugin_path}" 2>/dev/null)"
              install_hashes["${plugin_path}"]="${hash}"
            fi
            if [[ "${hash}" != "${sha}" ]]; then
              if (( force )); then
                bee::log_warning "${plugin_name}:${plugin_version} sha256 mismatch!" \
                  "Plugin was tampered with or version has been modified. Authenticity is not guaranteed." \
                  "Consider deleting ${plugin_path} and run 'bee install ${plugin_name}:${plugin_version}'."
                echo -e "${indent}${bullet}${BEE_COLOR_WARN}${BEE_CHECK_SUCCESS} ${plugin_name}:${plugin_version} (${url})${BEE_COLOR_RESET}"
              else
                bee::log_error "${plugin_name}:${plugin_version} sha256 mismatch!" "Deleting ${plugin_path}" \
                  "Use 'bee info ${plugin_name}:${plugin_version}' to inspect the plugin definition." \
                  "Use 'bee install --force ${plugin_name}:${plugin_version}' to install anyway and proceed at your own risk."
                rm -rf "${plugin_path}"
                echo -e "${indent}${bullet}${BEE_COLOR_FAIL}${BEE_CHECK_FAIL} ${plugin_name}:${plugin_version} (${url})${BEE_COLOR_RESET}"
              fi
            else
              if (( already_installed )); then
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
            if (( i == n - 1 ))
            then bee::install::recursively ${force} ${lock} "${indent}    " ${deps}
            else bee::install::recursively ${force} ${lock} "${indent}│   " ${deps}
            fi
          fi
        done < <(jq -r '[.git, .tag, .sha256, .dependencies[]?] | @tsv' "${spec_path}")
      done < <(bee::resolve "${plugin}" "${cache_path}" "plugin.json")
      (( found )) && break
    done
    if (( ! found )); then
      bee::load_plugin "${plugin}" 1
      if [[ -n "${BEE_LOAD_PLUGIN_NAME}" ]]; then
        (( lock )) && echo "${indent}${bullet}${BEE_LOAD_PLUGIN_NAME}:local" >> "${BEE_FILE}.lock"
        echo -e "${indent}${bullet}${BEE_LOAD_PLUGIN_NAME}:local (${BEE_LOAD_PLUGIN_PATH})"
        if [[ -f "${BEE_LOAD_PLUGIN_JSON_PATH}" ]]; then
          # shellcheck disable=SC2046,SC2086
          if (( i == n - 1 ))
          then bee::install::recursively ${force} ${lock} "${indent}    " $(jq -r '.dependencies[]?' "${BEE_LOAD_PLUGIN_JSON_PATH}")
          else bee::install::recursively ${force} ${lock} "${indent}│   " $(jq -r '.dependencies[]?' "${BEE_LOAD_PLUGIN_JSON_PATH}")
          fi
        fi
      else
        missing+=("${plugin}")
        echo -e "${indent}${bullet}${BEE_COLOR_FAIL}${BEE_CHECK_FAIL} ${plugin}${BEE_COLOR_RESET}"
      fi
    fi
  done
  if (( ${#missing[@]} )); then
    for m in "${missing[@]}"; do
      bee::log_error "Couldn't install plugin: ${m}"
    done
    return 1
  fi
}

main() {
  local -i force=0
  while (( $# )); do
    case "$1" in
      --force) force=1; shift ;;
      --) shift; break ;; *) break ;;
    esac
  done

  bee::pull

  if (( $# )); then
    echo "Installing"
    bee::install::recursively ${force} 0 "" "$@"
  elif [[ -v BEE_FILE ]]; then
    if [[ -f "${BEE_FILE}.lock" ]]; then
      echo "Installing plugins based on ${BEE_FILE}.lock"
      mapfile -t plugins < <(awk '/^├── / || /^└── / { if (!line[$2]++) print $2 }' "${BEE_FILE}.lock")
      bee::install::recursively ${force} 0 "" "${plugins[@]}"
    else
      echo "Installing plugins based on ${BEE_FILE}"
      bee::install::recursively ${force} 1 "" "${BEE_PLUGINS[@]}"
    fi
  else
    echo "No Beefile"
  fi
}

main "$@"
