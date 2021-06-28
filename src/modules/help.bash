bee::help() {
  local version entries
  version="$(cat "${BEE_HOME}/version.txt")"
  entries="$(bee::help::print_entries)"
  cat << EOF
🐝 bee ${version} - plugin-based bash automation

usage: bee [-h | --help] [--version]
           [-q | --quiet] [-v | --verbose]
           <command> [<args>]

${entries}

examples:
  bee version bump_minor
  bee changelog merge
  bee github me
EOF
}

bee::help::print_entries() {
  local header
  # shellcheck disable=SC2044
  for module in $(find "${BEE_MODULES_PATH}" -type f -mindepth 1 -maxdepth 1 -name "*.bash"); do
    header="$(head -n 1 "${module}")"
    if [[ "${header}" == "# bee::help"* ]]; then
      echo "  ${header:12}"
    fi
  done | sort -z | column -s '|' -t
}
