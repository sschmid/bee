# bee::help
# plugins [-a | --all | -o | --outdated]
#         [-v | --version] : list (all or outdated) plugins (with version)
# bee::help

bee::plugins::comp() {
  local comps=(--all -a --outdated -o --version -v)
  local IFS=' '
  while (($#)); do case "$1" in
    -a | --all) comps=("${comps[@]/--all}"); comps=("${comps[@]/-a}"); shift ;;
    -o | --outdated) comps=("${comps[@]/--outdated}"); comps=("${comps[@]/-o}"); shift ;;
    -v | --version) comps=("${comps[@]/--version}"); comps=("${comps[@]/-v}"); shift ;;
    --) shift; break ;; *) break ;;
  esac done
  compgen -W "${comps[*]}" -- "${1:-}"
}

bee::plugins() {
  local -i show_all=0
  local -i show_version=0
  local -i show_outdated=0
  while (($#)); do case "$1" in
    -a | --all) show_all=1; shift ;;
    -o | --outdated) show_outdated=1; shift ;;
    -v | --version) show_version=1; shift ;;
    --) shift; break ;; *) break ;;
  esac done

  if (($#)); then
    :
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
    done
  fi
}
