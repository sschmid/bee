########################################
# Print plugin information
# Arguments:
#   plugin
########################################

if (( ! $# )); then
  bee::source "bee-help"
  exit 1
fi

plugin="$1"

# shellcheck disable=SC2034
for url in "${BEE_HUBS[@]}"; do
  cache_path="${BEE_HUBS_CACHE_PATH}/$(bee::to_cache_path "${url}")"
  while read -r plugin_name plugin_version spec_path is_local; do
    spec_path="${spec_path}/${plugin_version}/plugin.json"
    echo "${spec_path}"
    jq . "${spec_path}" || cat "${spec_path}"
    exit
  done < <(bee::resolve "${plugin}" "${cache_path}" "plugin.json")
done

# shellcheck disable=SC2034
for path in "${BEE_PLUGINS_PATHS[@]}"; do
  while read -r plugin_name plugin_version spec_path is_local; do
    if (( is_local ))
    then spec_path="${spec_path}/plugin.json"
    else spec_path="${spec_path}/${plugin_version}/plugin.json"
    fi
    echo "${spec_path}"
    jq . "${spec_path}" || cat "${spec_path}"
    exit
  done < <(bee::resolve "${plugin}" "${path}" "plugin.json" 1)
done
