bee::help() {
  local version entries
  version="$(cat "${BEE_HOME}/version.txt")"
  entries="$(bee::help::print_entries)"
  echo "🐝 bee ${version} - plugin-based bash automation

usage: bee [-h | --help] [--version]
           [-q | --quiet] [-v | --verbose]
           [-b | --batch] <command> [<args>]

${entries}

examples:
  bee version bump_minor
  bee changelog merge
  bee github me"
}

bee::help::print_entries() {
  local module_path entry _
  while read -r -d '' module_path; do
    echo -e "$(basename "${module_path}" ".bash")\t${module_path}"
  done < <(find "${BEE_MODULES_PATH}" -type f -mindepth 1 -maxdepth 1 -name "*.bash" -print0) | sort | \
  while read -r _ module_path; do
    exec {help}< "${module_path}"
    read -r entry <&${help}
    if [[ "${entry}" == "# bee::help" ]]; then
      while read -r entry; do
        [[ "${entry}" == "# bee::help" ]] && echo && break
        echo "  ${entry:2}"
      done <&${help}
    fi
    exec {help}>&-
  done | awk -F ';' '{ printf "%-40s%s\n", $1, $2 }'
}
