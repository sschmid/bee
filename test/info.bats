setup() {
  load "test-helper.bash"
  load "test-helper-hub.bash"
  _set_beerc
}

@test "shows help when no args" {
  run bee info
  assert_failure
  assert_bee_help
}

@test "prints plugin info" {
  _setup_test_bee_hub_repo
  bee pull
  run bee info testplugin:1.0.0
  assert_success
  assert_output --partial "${BATS_TEST_TMPDIR}/cache/hubs/testhub/testplugin/1.0.0/plugin.json"
  assert_output --partial '"name": "testplugin"'
  assert_output --partial '"version": "1.0.0"'
}

@test "prints local plugin info" {
  # shellcheck disable=SC2030,SC2031
  export TEST_BEE_PLUGINS_PATHS_CUSTOM=1
  run bee info localplugin
  assert_success
  cat << EOF | assert_output -
${BATS_TEST_DIRNAME}/fixtures/custom_plugins/localplugin/plugin.json
{
  "dependencies": [
    "testplugin:1.0.0",
    "othertestplugin:1.0.0"
  ]
}
EOF
}

@test "prints plugin info from custom location" {
  # shellcheck disable=SC2030,SC2031
  export TEST_BEE_PLUGINS_PATHS_CUSTOM=1
  run bee info customtestplugin
  assert_success
  cat << EOF | assert_output -
${BATS_TEST_DIRNAME}/fixtures/custom_plugins/customtestplugin/1.0.0/plugin.json
{
  "dependencies": [
    "testplugin:1.0.0"
  ]
}
EOF
}

@test "prints plugin info when parsing error" {
  _setup_test_bee_hub_repo
  bee pull
  run bee info testplugin:0.2.0
  assert_success
  assert_output --partial '"name": "testplugin"'
  assert_output --partial '"version": "0.2.0"'
  assert_output --partial 'FORMAT-ERROR'
}

@test "completes bee info with plugin" {
  _setup_test_bee_hub_repo
  bee pull
  local expected=(othertestplugin testplugin testplugindeps testplugindepsdep testplugindepslatest testpluginmissingdep)
  assert_comp "bee info " "${expected[*]}"
}

@test "completes bee info with local plugin" {
  # shellcheck disable=SC2030,SC2031
  export TEST_BEE_PLUGINS_PATHS_CUSTOM=1
  _setup_test_bee_hub_repo
  bee pull
  local expected=(othertestplugin testplugin testplugindeps testplugindepsdep testplugindepslatest testpluginmissingdep customtestplugin localplugin)
  assert_comp "bee info " "${expected[*]}"
}

@test "no completion after plugin" {
  _setup_test_bee_hub_repo
  bee pull
  assert_comp "bee info testplugin "
}
