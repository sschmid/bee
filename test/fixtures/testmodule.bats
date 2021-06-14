setup() {
  load "test-helper.bash"
  local fixture="modules/bee-testmodule.sh"
  load "${fixture}"
  TEST_FIXTURE_PATH="${BATS_TEST_DIRNAME}/${fixture}"
}

@test "is not executable" {
  assert_file_not_executable "${TEST_FIXTURE_PATH}"
}

@test "fails on being sourced multiple times" {
  run source "${TEST_FIXTURE_PATH}"
  assert_failure
  assert_output "# ERROR: already sourced"
}

@test "prints message" {
  run bee::testmodule
  assert_output "hello from testmodule"
}

@test "prints message with args" {
  run bee::testmodule test
  assert_output "hello from testmodule - test"
}

@test "prints help" {
  run bee::testmodule::help
  assert_output "testmodule help"
}
