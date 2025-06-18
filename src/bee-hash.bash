########################################
# Compute combined hash of files in directory
# Arguments:
#   directory
# Outputs:
#   hash
########################################
main() {
  if (( ! $# )); then
    bee::source "bee-help"
    exit 1
  fi

  local path="$1" file_hash all
  local -a exclude=(^./.git .DS_Store$) hashes=()
  # shellcheck disable=SC2206
  [[ -v BEE_HUB_HASH_EXCLUDE ]] && exclude+=(${BEE_HUB_HASH_EXCLUDE//,/$'\n'})
  echo "${path}" >&2
  pushd "${path}" >/dev/null || exit 1
    local file pattern
    local -i ignore=0
    while IFS= read -r -d '' file; do
      ignore=0
      for pattern in "${exclude[@]}"; do
        if [[ "${file}" =~ ${pattern} ]]; then
          ignore=1
          break
        fi
      done
      if (( ! ignore )); then
        file_hash="$(os_sha256sum "${file}")"
        echo "${file_hash}" >&2
        hashes+=("${file_hash%% *}")
      fi
    done < <(find . -type f -print0 | LC_ALL=C sort -z)
  popd >/dev/null || exit 1

  all="$(echo "${hashes[*]}" | LC_ALL=C sort | os_sha256sum)"
  echo "${all}" >&2
  echo "${all%% *}"
}

main "$@"
