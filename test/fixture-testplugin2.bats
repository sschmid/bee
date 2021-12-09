setup() {
  load "test-helper.bash"
  local fixture="fixtures/plugins/testplugin/2.0.0/testplugin.bash"
  load "${fixture}"
  TEST_FIXTURE_PATH="${BATS_TEST_DIRNAME}/${fixture}"
}

@test "is not executable" {
  assert_file_not_executable "${TEST_FIXTURE_PATH}"
}

@test "prints message when sourced" {
  unset TESTPLUGIN_2_SOURCED
  run source "${TEST_FIXTURE_PATH}"
  assert_success
  assert_output "# testplugin 2.0.0 sourced"
}

@test "doesn't print message when TESTPLUGIN_QUIET " {
  unset TESTPLUGIN_2_SOURCED
  export TESTPLUGIN_QUIET=1
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
  assert_output "hello from testplugin 2.0.0"
}

@test "prints message with args" {
  run testplugin test
  assert_success
  assert_output "hello from testplugin 2.0.0 - test"
}

@test "prints help" {
  run testplugin::help
  assert_success
  assert_output "testplugin 2.0.0 help"
}

@test "greets" {
  run testplugin::greet
  assert_success
  assert_output "greeting from testplugin 2.0.0"
}

@test "greets with args" {
  run testplugin::greet "test"
  assert_success
  assert_output "greeting test from testplugin 2.0.0"
}
