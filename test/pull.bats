setup() {
  load 'test-helper'
  _common_setup
  _export_beerc
  _source_beerc
  BEE_HUBS_CACHE_PATH="${BEE_CACHE_PATH}/hubs"
}

@test "clones all registered hubs" {
  _create_mock_bee_hub_repo ${TEST_HUB_1} testplugin
  _create_mock_bee_hub_repo ${TEST_HUB_2} othertestplugin
  run bee pull
  assert_success
  assert_file_exist "${BEE_HUBS_CACHE_PATH}/${TEST_HUB_1}/testplugin/1.0.0/plugin.json"
  assert_file_exist "${BEE_HUBS_CACHE_PATH}/${TEST_HUB_2}/othertestplugin/1.0.0/plugin.json"
}

@test "clones specified hubs" {
  _create_mock_bee_hub_repo ${TEST_HUB_1} testplugin
  _create_mock_bee_hub_repo ${TEST_HUB_2} othertestplugin
  run bee pull "file://${BATS_TEST_TMPDIR}/${TEST_HUB_1}"
  assert_success
  assert_file_exist "${BEE_HUBS_CACHE_PATH}/${TEST_HUB_1}/testplugin/1.0.0/plugin.json"
  assert_dir_not_exist "${BEE_HUBS_CACHE_PATH}/${TEST_HUB_2}"
}

@test "ignores cloning unknown hubs" {
  _create_mock_bee_hub_repo ${TEST_HUB_1} testplugin
  _create_mock_bee_hub_repo ${TEST_HUB_2} othertestplugin
  # shellcheck disable=SC2016
  _export_beerc_with 'BEE_HUBS=("file://${BATS_TEST_TMPDIR}/${TEST_HUB_1}" "unknown" "file://${BATS_TEST_TMPDIR}/${TEST_HUB_2}")'
  run bee pull
  assert_success
  assert_output --partial "${BEE_WARNING} Unsupported url: unknown"
  assert_file_exist "${BEE_HUBS_CACHE_PATH}/${TEST_HUB_1}/testplugin/1.0.0/plugin.json"
  assert_dir_not_exist "${BEE_HUBS_CACHE_PATH}/unknown"
  assert_file_exist "${BEE_HUBS_CACHE_PATH}/${TEST_HUB_2}/othertestplugin/1.0.0/plugin.json"
}

@test "pulls existing hubs" {
  _create_mock_bee_hub_repo ${TEST_HUB_1} testplugin
  _export_beerc_with 'BEE_HUB_PULL_COOLDOWN=-1'
  bee pull
  assert_file_not_exist "${BEE_HUBS_CACHE_PATH}/${TEST_HUB_1}/testplugin/2.0.0/plugin.json"

  _update_mock_bee_hub_repo ${TEST_HUB_1} testplugin
  run bee pull
  assert_success
  assert_file_exist "${BEE_HUBS_CACHE_PATH}/${TEST_HUB_1}/testplugin/2.0.0/plugin.json"
}

@test "pulls test hub" {
  _create_bee_hub_repo "${TEST_HUB_1}"
  # shellcheck disable=SC2016
  _export_beerc_with 'BEE_HUBS=("file://${BATS_TEST_TMPDIR}/${TEST_HUB_1}")'
  run bee pull
  assert_file_exist "${BEE_HUBS_CACHE_PATH}/${TEST_HUB_1}/testplugin/1.0.0/plugin.json"
  assert_file_exist "${BEE_HUBS_CACHE_PATH}/${TEST_HUB_1}/testplugin/2.0.0/plugin.json"
  assert_file_exist "${BEE_HUBS_CACHE_PATH}/${TEST_HUB_1}/othertestplugin/1.0.0/plugin.json"
  assert_file_exist "${BEE_HUBS_CACHE_PATH}/${TEST_HUB_1}/testplugindeps/1.0.0/plugin.json"
  assert_file_exist "${BEE_HUBS_CACHE_PATH}/${TEST_HUB_1}/testplugindepsdep/1.0.0/plugin.json"
  assert_file_exist "${BEE_HUBS_CACHE_PATH}/${TEST_HUB_1}/testpluginmissingdep/1.0.0/plugin.json"
}

@test "pull sets ts" {
  _create_mock_bee_hub_repo ${TEST_HUB_1} testplugin
  run bee pull "file://${BATS_TEST_TMPDIR}/${TEST_HUB_1}"
  assert_success
  assert_file_exist "${BEE_HUBS_CACHE_PATH}/.bee_pull_cooldown"
}

@test "skips pull when within cooldown period" {
  _create_mock_bee_hub_repo ${TEST_HUB_1} testplugin
  _create_mock_bee_hub_repo ${TEST_HUB_2} othertestplugin
  _export_beerc_with 'BEE_HUB_PULL_COOLDOWN=1'
  bee pull "file://${BATS_TEST_TMPDIR}/${TEST_HUB_1}"

  run bee pull "file://${BATS_TEST_TMPDIR}/${TEST_HUB_2}"
  assert_success
  assert_file_exist "${BEE_HUBS_CACHE_PATH}/${TEST_HUB_1}/testplugin/1.0.0/plugin.json"
  assert_file_not_exist "${BEE_HUBS_CACHE_PATH}/${TEST_HUB_2}/othertestplugin/1.0.0/plugin.json"

  sleep 3
  run bee pull "file://${BATS_TEST_TMPDIR}/${TEST_HUB_2}"
  assert_file_exist "${BEE_HUBS_CACHE_PATH}/${TEST_HUB_2}/othertestplugin/1.0.0/plugin.json"
}

@test "forces pull even when within cooldown period" {
  _create_mock_bee_hub_repo ${TEST_HUB_1} testplugin
  _create_mock_bee_hub_repo ${TEST_HUB_2} othertestplugin
  _export_beerc_with 'BEE_HUB_PULL_COOLDOWN=999'

  run bee pull "file://${BATS_TEST_TMPDIR}/${TEST_HUB_1}"
  assert_success
  assert_file_exist "${BEE_HUBS_CACHE_PATH}/${TEST_HUB_1}/testplugin/1.0.0/plugin.json"
  assert_dir_not_exist "${BEE_HUBS_CACHE_PATH}/${TEST_HUB_2}"

  run bee pull --force
  assert_success
  assert_file_exist "${BEE_HUBS_CACHE_PATH}/${TEST_HUB_2}/othertestplugin/1.0.0/plugin.json"
}

@test "completes bee pull with options and hub urls" {
  local expected=(--force "file://${BATS_TEST_TMPDIR}/${TEST_HUB_1}" "file://${BATS_TEST_TMPDIR}/${TEST_HUB_2}")
  assert_comp "bee pull " "${expected[*]}"
}

@test "completes bee pull with multiple hub urls" {
  local expected=("file://${BATS_TEST_TMPDIR}/${TEST_HUB_1}" "file://${BATS_TEST_TMPDIR}/${TEST_HUB_2}")
  assert_comp "bee pull myurl " "${expected[*]}"
}
