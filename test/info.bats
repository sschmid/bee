setup() {
  load 'test-helper'
  _common_setup
  _export_beerc
}

@test "shows help when no args" {
  run bee info
  assert_failure
  assert_bee_help
}

@test "prints plugin info" {
  _create_bee_hub_repo "${TEST_HUB_1}"
  bee pull
  run bee info plugin_1:1.0.0
  assert_success
  assert_output --partial "${BATS_TEST_TMPDIR}/cache/hubs/${TEST_HUB_1}/plugin_1/1.0.0/plugin.json"
  assert_output --partial '"name": "plugin_1"'
  assert_output --partial '"version": "1.0.0"'
}

@test "prints local plugin info" {
  # shellcheck disable=SC2030,SC2031
  export TEST_BEE_PLUGINS_PATHS_CUSTOM=1
  run bee info local_plugin
  assert_success
  cat << EOF | assert_output -
${BATS_TEST_DIRNAME}/fixtures/custom_plugins/local_plugin/plugin.json
{
  "dependencies": [
    "plugin_1:1.0.0",
    "plugin_2:1.0.0"
  ]
}
EOF
}

@test "prints plugin info from custom location" {
  # shellcheck disable=SC2030,SC2031
  export TEST_BEE_PLUGINS_PATHS_CUSTOM=1
  run bee info custom_plugin
  assert_success
  cat << EOF | assert_output -
${BATS_TEST_DIRNAME}/fixtures/custom_plugins/custom_plugin/1.0.0/plugin.json
{
  "dependencies": [
    "plugin_1:1.0.0",
    "plugin_2:1.0.0"
  ]
}
EOF
}

@test "prints plugin info when parsing error" {
  _create_bee_hub_repo "${TEST_HUB_1}"
  bee pull
  run bee info plugin_1:0.2.0
  assert_success
  assert_output --partial '"name": "plugin_1"'
  assert_output --partial '"version": "0.2.0"'
  assert_output --partial 'FORMAT-ERROR'
}

@test "completes bee info with plugin" {
  _create_bee_hub_repo "${TEST_HUB_1}"
  bee pull
  assert_comp "bee info " "${ALL_TEST_PLUGINS[*]} testplugindepslatest"
}

@test "completes bee info with custom plugin" {
  # shellcheck disable=SC2030,SC2031
  export TEST_BEE_PLUGINS_PATHS_CUSTOM=1
  _create_bee_hub_repo "${TEST_HUB_1}"
  bee pull
  assert_comp "bee info " "${ALL_TEST_PLUGINS[*]} ${ALL_CUSTOM_PLUGINS[*]} testplugindepslatest"
}

@test "no completion after plugin" {
  _create_bee_hub_repo "${TEST_HUB_1}"
  bee pull
  assert_comp "bee info plugin_1 "
}
