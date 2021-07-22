setup() {
  load "test-helper.bash"
  local fixture="modules/othertestmodule.bash"
  load "${fixture}"
  TEST_FIXTURE_PATH="${BATS_TEST_DIRNAME}/${fixture}"
}

@test "is not executable" {
  assert_file_not_executable "${TEST_FIXTURE_PATH}"
}

@test "prints message when sourced" {
  unset BEE_OTHERTESTMODULE_SOURCED
  run source "${TEST_FIXTURE_PATH}"
  assert_output "# othertestmodule sourced"
}

@test "fails on being sourced multiple times" {
  run source "${TEST_FIXTURE_PATH}"
  assert_failure
  assert_output "# ERROR: already sourced"
}

@test "prints message" {
  run _strict bee::othertestmodule
  assert_output "hello from othertestmodule"
}

@test "prints message with args" {
  run _strict bee::othertestmodule test
  assert_output "hello from othertestmodule - test"
}

@test "prints help" {
  run _strict bee::othertestmodule::help
  assert_output "othertestmodule help"
}
