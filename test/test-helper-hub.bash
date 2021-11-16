_setup_test_bee_hub_repo() {
  local name="${1:-"testhub"}"
  mkdir -p "${BATS_TEST_TMPDIR}/${name}"
  cp -r "${BATS_TEST_DIRNAME}/fixtures/hub/." "${BATS_TEST_TMPDIR}/${name}"
  pushd "${BATS_TEST_TMPDIR}/${name}" > /dev/null || exit 1
    local file
    while read -r -d '' file; do
      sed -i.bak -e "s;HOME;${BATS_TEST_TMPDIR};" -- "${file}" && rm "${file}.bak"
    done < <(find . -type f -name "plugin.json" -print0)
    git init -b main; git add . ; _git_commit -m "Initial commit"
  popd > /dev/null || exit 1
}
