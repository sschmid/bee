setup() {
  load 'test-helper'
  _common_setup
  local fixture="fixtures/plugins/plugin_2/1.0.0/plugin_2.bash"
  load "${fixture}"
  TEST_FIXTURE_PATH="${BATS_TEST_DIRNAME}/${fixture}"
}

@test "prints message when sourced" {
  unset OTHERTEST_PLUGIN_SOURCED
  run source "${TEST_FIXTURE_PATH}"
  assert_success
  assert_output "# plugin_2 1.0.0 sourced"
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
  run plugin_2
  assert_success
  assert_output "hello from plugin_2 1.0.0"
}

@test "prints message with args" {
  run plugin_2 test
  assert_success
  assert_output "hello from plugin_2 1.0.0 - test"
}

@test "prints help" {
  run plugin_2::help
  assert_success
  assert_output "plugin_2 1.0.0 help"
}

@test "greets" {
  run plugin_2::greet
  assert_success
  assert_output "greeting from plugin_2 1.0.0"
}

@test "greets with args" {
  run plugin_2::greet "test"
  assert_success
  assert_output "greeting test from plugin_2 1.0.0"
}
