setup() {
  load "test-helper.bash"
  local fixture="fixtures/plugins/othertestplugin/1.0.0/othertestplugin.bash"
  load "${fixture}"
  TEST_FIXTURE_PATH="${BATS_TEST_DIRNAME}/${fixture}"
}

@test "prints message when sourced" {
  unset OTHERTEST_PLUGIN_SOURCED
  run source "${TEST_FIXTURE_PATH}"
  assert_success
  assert_output "# othertestplugin 1.0.0 sourced"
}

@test "doesn't print message when TEST_PLUGIN_QUIET " {
  unset OTHERTEST_PLUGIN_SOURCED
  export TEST_PLUGIN_QUIET=1
  run source "${TEST_FIXTURE_PATH}"
  assert_success
  refute_output
}

@test "fails on being sourced multiple times" {
  run source "${TEST_FIXTURE_PATH}"
  assert_failure
  assert_output "# ERROR: already sourced"
}

@test "prints message" {
  run othertestplugin
  assert_success
  assert_output "hello from othertestplugin 1.0.0"
}

@test "prints message with args" {
  run othertestplugin test
  assert_success
  assert_output "hello from othertestplugin 1.0.0 - test"
}

@test "prints help" {
  run othertestplugin::help
  assert_success
  assert_output "othertestplugin 1.0.0 help"
}

@test "greets" {
  run othertestplugin::greet
  assert_success
  assert_output "greeting from othertestplugin 1.0.0"
}

@test "greets with args" {
  run othertestplugin::greet "test"
  assert_success
  assert_output "greeting test from othertestplugin 1.0.0"
}
