bee::help() {
  local version entries
  version="$(cat "${BEE_HOME}/version.txt")"
  entries="$(bee::help::print_entries)"
  cat << EOF

██████╗ ███████╗███████╗
██╔══██╗██╔════╝██╔════╝
██████╔╝█████╗  █████╗
██╔══██╗██╔══╝  ██╔══╝
██████╔╝███████╗███████╗
╚═════╝ ╚══════╝╚══════╝

${BEE_ICON} bee ${version} - plugin-based bash automation

usage: bee [-h | --help] [--version]
           [-q | --quiet] [-v | --verbose]
           [-b | --batch] <command> [<args>]

${entries}

EOF
}

bee::help::print_entries() {
  local module_path entry _
  while read -r -d '' module_path; do
    echo -e "$(basename "${module_path}" ".bash")\t${module_path}"
  done < <(find "${BEE_MODULES_PATH}" -mindepth 1 -maxdepth 1 -type f -name "*.bash" -print0) | sort |
    while read -r _ module_path; do
      exec {help}< "${module_path}"
      read -r entry <&${help}
      if [[ "${entry}" == "# bee::help" ]]; then
        while read -r entry; do
          [[ "${entry}" == "# bee::help" ]] && break
          echo "  ${entry:2}"
        done <&${help}
      fi
      exec {help}>&-
    done | awk -F ':' '{ printf "%-42s%s\n", $1, $2 }'
}
