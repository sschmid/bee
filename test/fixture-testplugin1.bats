setup() {
  load "test-helper.bash"
  local fixture="fixtures/plugins/testplugin/1.0.0/testplugin.bash"
  load "${fixture}"
  TEST_FIXTURE_PATH="${BATS_TEST_DIRNAME}/${fixture}"
}

@test "prints message when sourced" {
  unset TEST_PLUGIN_1_SOURCED
  run source "${TEST_FIXTURE_PATH}"
  assert_success
  assert_output "# testplugin 1.0.0 sourced"
}

@test "doesn't print message when TEST_PLUGIN_QUIET " {
  unset TEST_PLUGIN_1_SOURCED
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
  run testplugin
  assert_success
  assert_output "hello from testplugin 1.0.0"
}

@test "prints message with args" {
  run testplugin test
  assert_success
  assert_output "hello from testplugin 1.0.0 - test"
}

@test "prints help" {
  run testplugin::help
  assert_success
  assert_output "testplugin 1.0.0 help"
}

@test "greets" {
  run testplugin::greet
  assert_success
  assert_output "greeting from testplugin 1.0.0"
}

@test "greets with args" {
  run testplugin::greet "test"
  assert_success
  assert_output "greeting test from testplugin 1.0.0"
}
