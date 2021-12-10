setup() {
  load "test-helper.bash"
  load "test-helper-hub.bash"
  _set_beerc
}

@test "shows help when no args" {
  run bee info
  assert_bee_help
}

@test "prints plugin info" {
  _setup_test_bee_hub_repo
  bee pull
  run bee info testplugin:1.0.0
  assert_success
  assert_output --partial '"name": "testplugin"'
  assert_output --partial '"version": "1.0.0"'
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
  local expected=(othertestplugin testplugin testplugindeps testplugindepsdep testpluginmissingdep)
  assert_comp "bee info " "${expected[*]}"
}

@test "no completion after plugin" {
  _setup_test_bee_hub_repo
  bee pull
  assert_comp "bee info testplugin "
}

