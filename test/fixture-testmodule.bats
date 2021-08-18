setup() {
  load "test-helper.bash"
  local fixture="fixtures/modules/testmodule.bash"
  load "${fixture}"
  TEST_FIXTURE_PATH="${BATS_TEST_DIRNAME}/${fixture}"
}

@test "is not executable" {
  assert_file_not_executable "${TEST_FIXTURE_PATH}"
}

@test "prints message when sourced" {
  unset BEE_TESTMODULE_SOURCED
  run source "${TEST_FIXTURE_PATH}"
  assert_output "# testmodule sourced"
}

@test "fails on being sourced multiple times" {
  run source "${TEST_FIXTURE_PATH}"
  assert_failure
  assert_output "# ERROR: already sourced"
}

@test "prints message" {
  run _strict bee::testmodule
  assert_output "hello from testmodule"
}

@test "prints message with args" {
  run _strict bee::testmodule test
  assert_output "hello from testmodule - test"
}

@test "prints help" {
  run _strict bee::testmodule::help
  assert_output "testmodule help"
}
