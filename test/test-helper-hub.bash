_setup_test_bee_hub_repo() {
  local name="${1:-"testhub"}"
  mkdir -p "${BATS_TEST_TMPDIR}/${name}"
  cp -r "${BATS_TEST_DIRNAME}/fixtures/hub/." "${BATS_TEST_TMPDIR}/${name}"
  pushd "${BATS_TEST_TMPDIR}/${name}" >/dev/null || exit 1
    local file
    while read -r -d '' file; do
      sed -i.bak -e "s;HOME;${BATS_TEST_TMPDIR};" -- "${file}" && rm "${file}.bak"
    done < <(find . -type f -name "plugin.json" -print0)
    git init; git add . ; _git_commit -m "Initial commit"
  popd >/dev/null || exit 1
}

_setup_empty_bee_hub_repo() {
  mkdir -p "${BATS_TEST_TMPDIR}/$1"
  pushd "${BATS_TEST_TMPDIR}/$1" >/dev/null || exit 1
    echo "empty" > empty.txt
    git init; git add . ; _git_commit -m "Initial commit"
  popd >/dev/null || exit 1
}

_setup_generic_plugin_repo() {
  local version="${2:-"1.0.0"}"
  mkdir -p "${BATS_TEST_TMPDIR}/plugins"
  cp -r "${BATS_TEST_DIRNAME}/fixtures/plugins/$1/${version}/." "${BATS_TEST_TMPDIR}/plugins/$1"
  pushd "${BATS_TEST_TMPDIR}/plugins/$1" >/dev/null || exit 1
    git init; git add . ; _git_commit -m "Initial commit"; git tag "v${version}"
  popd >/dev/null || exit 1
}

_update_generic_plugin_repo() {
  cp -r "${BATS_TEST_DIRNAME}/fixtures/plugins/$1/2.0.0/." "${BATS_TEST_TMPDIR}/plugins/$1"
  pushd "${BATS_TEST_TMPDIR}/plugins/$1" >/dev/null || exit 1
    git add . ; _git_commit -m "Release 2.0.0"; git tag "v2.0.0"
  popd >/dev/null || exit 1
}

_setup_testplugin_repo() {
  _setup_generic_plugin_repo testplugin
  _update_generic_plugin_repo testplugin
}
