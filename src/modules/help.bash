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
  local module entry
  while read -r -d '' module; do
    exec {help}< "${module}"
    read -r entry <&${help}
    if [[ "${entry}" == "# bee::help" ]]; then
      while read -r entry; do
        [[ "${entry}" == "# bee::help" ]] && break
        echo "  ${entry:2}"
      done <&${help}
    fi
    exec {help}>&-
  done < <(find "${BEE_MODULES_PATH}" -type f -mindepth 1 -maxdepth 1 -name "*.bash" -print0) | column -s ';' -t
}
