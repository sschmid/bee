_create_bee_hub_repo() {
  __prepare_hub_creation "$@"
    cp -r "${BATS_TEST_DIRNAME}/fixtures/hub/" .
    local file
    while IFS= read -r -d '' file; do
      sed -i.bak -e "s;\$HOME;${BATS_TEST_TMPDIR};" -- "${file}" && rm "${file}.bak"
    done < <(find . -type f -name "plugin.json" -print0)
  __finish_hub_creation "$@"
}

_create_empty_bee_hub_repo() {
  __prepare_hub_creation "$@"
    echo "empty" >empty.txt
  __finish_hub_creation "$@"
}

_create_generic_plugin_repo() {
  local plugin_name="$1" version="${2:-"1.0.0"}"
  mkdir -p "${BATS_TEST_TMPDIR}/plugins"
  cp -r "${BATS_TEST_DIRNAME}/fixtures/plugins/${plugin_name}/${version}/" "${BATS_TEST_TMPDIR}/plugins/${plugin_name}"
  pushd "${BATS_TEST_TMPDIR}/plugins/${plugin_name}" >/dev/null || exit 1
    git init
    git add .
    _git_commit -m "Initial commit"
    git tag "v${version}"
  popd >/dev/null || exit 1
}

_update_generic_plugin_repo() {
  local plugin_name="$1" version="${2:-"2.0.0"}"
  cp -r "${BATS_TEST_DIRNAME}/fixtures/plugins/${plugin_name}/${version}/" "${BATS_TEST_TMPDIR}/plugins/${plugin_name}"
  pushd "${BATS_TEST_TMPDIR}/plugins/${plugin_name}" >/dev/null || exit 1
    git add .
    _git_commit -m "Release ${version}"
    git tag "v2.0.0"
  popd >/dev/null || exit 1
}

_setup_testplugin_repo() {
  _create_generic_plugin_repo testplugin
  _update_generic_plugin_repo testplugin
}

__prepare_hub_creation() {
  local name="${1:-"testhub"}"
  mkdir -p "${BATS_TEST_TMPDIR}/${name}"
  pushd "${BATS_TEST_TMPDIR}/${name}" >/dev/null || exit 1
}

__finish_hub_creation() {
  git init
  git add .
  _git_commit -m "Initial commit"
  popd >/dev/null || exit 1
}
