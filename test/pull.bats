setup() {
  load "test-helper.bash"
  load "test-helper-hub.bash"
  _set_beerc
  _source_beerc
  BEE_HUBS_CACHE_PATH="${BEE_CACHES_PATH}/hubs"
}

_setup_mock_bee_hub_repo() {
  local hub="$1" plugin="$2"
  mkdir -p "${BATS_TEST_TMPDIR}/${hub}/${plugin}/1.0.0"
  pushd "${BATS_TEST_TMPDIR}/${hub}" > /dev/null || exit 1
    touch "${plugin}/1.0.0/plugin.json"
    git init -b main; git add . ; _git_commit -m "Initial commit"
  popd > /dev/null || exit 1
}

_update_mock_bee_hub_repo() {
  local hub="$1" plugin="$2" version="$3"
  mkdir -p "${BATS_TEST_TMPDIR}/${hub}/${plugin}/${version}"
  pushd "${BATS_TEST_TMPDIR}/${hub}" > /dev/null || exit 1
    touch "${plugin}/${version}/plugin.json"; git add . ; _git_commit -m "Release ${version}"
  popd > /dev/null || exit 1
}

@test "clones all registered hubs" {
  _setup_mock_bee_hub_repo testhub testplugin
  _setup_mock_bee_hub_repo othertesthub othertestplugin
  run bee pull
  assert_success
  assert_file_exist "${BEE_HUBS_CACHE_PATH}/testhub/testplugin/1.0.0/plugin.json"
  assert_file_exist "${BEE_HUBS_CACHE_PATH}/othertesthub/othertestplugin/1.0.0/plugin.json"
}

@test "clones specified hubs" {
  _setup_mock_bee_hub_repo testhub testplugin
  _setup_mock_bee_hub_repo othertesthub othertestplugin
  run bee pull "file://${BATS_TEST_TMPDIR}/testhub"
  assert_success
  assert_file_exist "${BEE_HUBS_CACHE_PATH}/testhub/testplugin/1.0.0/plugin.json"
  assert_dir_not_exist "${BEE_HUBS_CACHE_PATH}/othertesthub"
}

@test "ignores cloning unknown hubs" {
  _setup_mock_bee_hub_repo testhub testplugin
  _setup_mock_bee_hub_repo othertesthub othertestplugin
  # shellcheck disable=SC2016
  _set_beerc_with 'BEE_HUBS=("file://${BATS_TEST_TMPDIR}/testhub" "unknown" "file://${BATS_TEST_TMPDIR}/othertesthub")'
  run bee pull
  assert_success
  assert_output --partial "${BEE_WARN} Unsupported hub url: unknown"
  assert_file_exist "${BEE_HUBS_CACHE_PATH}/testhub/testplugin/1.0.0/plugin.json"
  assert_dir_not_exist "${BEE_HUBS_CACHE_PATH}/unknown"
  assert_file_exist "${BEE_HUBS_CACHE_PATH}/othertesthub/othertestplugin/1.0.0/plugin.json"
}

@test "pulls existing hubs" {
  _setup_mock_bee_hub_repo testhub testplugin
  _set_beerc_with 'BEE_HUB_PULL_COOLDOWN=-1'
  bee pull
  assert_file_not_exist "${BEE_HUBS_CACHE_PATH}/testhub/testplugin/2.0.0/plugin.json"

  _update_mock_bee_hub_repo testhub testplugin 2.0.0
  run bee pull
  assert_success
  assert_file_exist "${BEE_HUBS_CACHE_PATH}/testhub/testplugin/2.0.0/plugin.json"
}

@test "pulls test hub" {
  _setup_test_bee_hub_repo
  # shellcheck disable=SC2016
  _set_beerc_with 'BEE_HUBS=("file://${BATS_TEST_TMPDIR}/testhub")'
  run bee pull
  assert_file_exist "${BEE_HUBS_CACHE_PATH}/testhub/testplugin/1.0.0/plugin.json"
  assert_file_exist "${BEE_HUBS_CACHE_PATH}/testhub/testplugin/2.0.0/plugin.json"
  assert_file_exist "${BEE_HUBS_CACHE_PATH}/testhub/othertestplugin/1.0.0/plugin.json"
  assert_file_exist "${BEE_HUBS_CACHE_PATH}/testhub/testplugindeps/1.0.0/plugin.json"
  assert_file_exist "${BEE_HUBS_CACHE_PATH}/testhub/testplugindepsdep/1.0.0/plugin.json"
  assert_file_exist "${BEE_HUBS_CACHE_PATH}/testhub/testpluginmissingdep/1.0.0/plugin.json"
}

@test "pull sets ts" {
  _setup_mock_bee_hub_repo testhub testplugin
  run bee pull "file://${BATS_TEST_TMPDIR}/testhub"
  assert_success
  assert_file_exist "${BEE_HUBS_CACHE_PATH}/.bee_pull_cooldown"
}

@test "skips pull when within cooldown period" {
  _setup_mock_bee_hub_repo testhub testplugin
  _setup_mock_bee_hub_repo othertesthub othertestplugin
  _set_beerc_with 'BEE_HUB_PULL_COOLDOWN=1'
  bee pull "file://${BATS_TEST_TMPDIR}/testhub"

  run bee pull "file://${BATS_TEST_TMPDIR}/othertesthub"
  assert_success
  assert_file_exist "${BEE_HUBS_CACHE_PATH}/testhub/testplugin/1.0.0/plugin.json"
  assert_file_not_exist "${BEE_HUBS_CACHE_PATH}/othertesthub/othertestplugin/1.0.0/plugin.json"

  sleep 3
  run bee pull "file://${BATS_TEST_TMPDIR}/othertesthub"
  assert_file_exist "${BEE_HUBS_CACHE_PATH}/othertesthub/othertestplugin/1.0.0/plugin.json"
}

@test "forces pull even when within cooldown period" {
  _setup_mock_bee_hub_repo testhub testplugin
  _setup_mock_bee_hub_repo othertesthub othertestplugin
  _set_beerc_with 'BEE_HUB_PULL_COOLDOWN=999'

  run bee pull "file://${BATS_TEST_TMPDIR}/testhub"
  assert_success
  assert_file_exist "${BEE_HUBS_CACHE_PATH}/testhub/testplugin/1.0.0/plugin.json"
  assert_dir_not_exist "${BEE_HUBS_CACHE_PATH}/othertesthub"

  run bee pull --force
  assert_success
  assert_file_exist "${BEE_HUBS_CACHE_PATH}/othertesthub/othertestplugin/1.0.0/plugin.json"
}

@test "completes bee pull with options and hub urls" {
  local expected=(--force "file://${BATS_TEST_TMPDIR}/testhub" "file://${BATS_TEST_TMPDIR}/othertesthub")
  assert_comp "bee pull " "${expected[*]}"
}

@test "completes bee pull with multiple hub urls" {
  local expected=("file://${BATS_TEST_TMPDIR}/testhub" "file://${BATS_TEST_TMPDIR}/othertesthub")
  assert_comp "bee pull myurl " "${expected[*]}"
}
