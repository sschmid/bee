bee::help() {
  local version entries
  version="$(cat "${BEE_HOME}/version.txt")"
  entries="$(bee::help::print_entries)"
  cat << EOF
🐝 bee ${version} - plugin-based bash automation

usage: bee [-h | --help] [--version]
           [-q | --quiet] [-v | --verbose]
           [-b | --batch] <command> [<args>]

${entries}

examples:
  bee version bump_minor
  bee changelog merge
  bee github me
EOF
}

bee::help::print_entries() {
  local header module
  while read -r -d '' module; do
    header="$(head -n 1 "${module}")"
    [[ "${header}" == "# bee::help"* ]] && echo "  ${header:12}"
  done < <(find "${BEE_MODULES_PATH}" -type f -mindepth 1 -maxdepth 1 -name "*.bash" -print0) | sort | column -s '|' -t
}
