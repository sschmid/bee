# bee::help
# plugins : list enabled plugins
# bee::help

bee::plugins() {
  local -i show_version=0
  local -i show_outdated=0
  while (($#)); do case "$1" in
    -o | --outdated) show_outdated=1; shift ;;
    -v | --version) show_version=1; shift ;;
    --) shift; break ;; *) break ;;
  esac done

  if (($#)); then
    :
  else
    local plugin_entry plugin_version
    for plugin in "${BEE_PLUGINS[@]}"; do
      bee::resolve_plugin "${plugin}"
      if [[ -n "${BEE_RESOLVE_PLUGIN_PATH}" ]]; then
        plugin_entry="${BEE_RESOLVE_PLUGIN_NAME}"
        plugin_version="${BEE_RESOLVE_PLUGIN_VERSION}"
        ((show_version || show_outdated)) && plugin_entry="${plugin_entry}:${plugin_version}"
        if ((show_outdated)); then
          bee::resolve_plugin "${BEE_RESOLVE_PLUGIN_NAME}"
          if [[ -n "${BEE_RESOLVE_PLUGIN_PATH}" && "${BEE_RESOLVE_PLUGIN_VERSION}" != "${plugin_version}" ]]; then
            plugin_entry="${plugin_entry} ➜ ${BEE_RESOLVE_PLUGIN_NAME}:${BEE_RESOLVE_PLUGIN_VERSION}"
          fi
        fi
        echo "${plugin_entry}"
      else
        echo -e "\033[31m✗ ${plugin}\033[0m"
      fi
    done
  fi
}
