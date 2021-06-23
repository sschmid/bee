setup() {
  load "test-helper.bash"
  local fixture="plugins/testplugin/1.0.0/testplugin.bash"
  load "${fixture}"
  TEST_FIXTURE_PATH="${BATS_TEST_DIRNAME}/${fixture}"
}

@test "is not executable" {
  assert_file_not_executable "${TEST_FIXTURE_PATH}"
}

@test "prints message when sourced" {
  unset TESTPLUGIN_1_SOURCED
  run source "${TEST_FIXTURE_PATH}"
  assert_output "# testplugin 1.0.0 sourced"
}

@test "fails on being sourced multiple times" {
  run source "${TEST_FIXTURE_PATH}"
  assert_failure
  assert_output "# ERROR: already sourced"
}

@test "prints message" {
  run testplugin
  assert_output "hello from testplugin 1.0.0"
}

@test "prints message with args" {
  run testplugin test
  assert_output "hello from testplugin 1.0.0 - test"
}

@test "prints help" {
  run testplugin::help
  assert_output "testplugin 1.0.0 help"
}

@test "greets" {
  run testplugin::greet
  assert_output "greeting from testplugin 1.0.0"
}

@test "greets with args" {
  run testplugin::greet "test"
  assert_output "greeting test from testplugin 1.0.0"
}
