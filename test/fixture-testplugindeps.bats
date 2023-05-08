setup() {
  load "test-helper.bash"
  local fixture="fixtures/plugins/testplugindeps/1.0.0/testplugindeps.bash"
  load "${fixture}"
  TEST_FIXTURE_PATH="${BATS_TEST_DIRNAME}/${fixture}"
}

@test "prints message when sourced" {
  run source "${TEST_FIXTURE_PATH}"
  assert_success
  assert_output "# testplugindeps 1.0.0 sourced"
}

@test "doesn't print message when TEST_PLUGIN_QUIET " {
  export TEST_PLUGIN_QUIET=1
  run source "${TEST_FIXTURE_PATH}"
  assert_success
  refute_output
}

@test "prints message" {
  run testplugindeps
  assert_success
  assert_output "hello from testplugindeps 1.0.0"
}

@test "prints message with args" {
  run testplugindeps test
  assert_success
  assert_output "hello from testplugindeps 1.0.0 - test"
}

@test "fails to call deps" {
  run -127 testplugindeps::greet
  assert_failure
  assert_output --partial "greeting from testplugindeps 1.0.0"
  assert_output --partial "testplugin::greet: command not found"
  assert_output --partial "othertestplugin::greet: command not found"
}
