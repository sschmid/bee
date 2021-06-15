setup() {
  load "test-helper.bash"
  local fixture="plugins/othertestplugin/1.0.0/othertestplugin.sh"
  load "${fixture}"
  TEST_FIXTURE_PATH="${BATS_TEST_DIRNAME}/${fixture}"
}

@test "is not executable" {
  assert_file_not_executable "${TEST_FIXTURE_PATH}"
}

@test "prints message when sourced" {
  unset OTHERTESTPLUGIN_SOURCED
  run source "${TEST_FIXTURE_PATH}"
  assert_output "# othertestplugin 1.0.0 sourced"
}

@test "fails on being sourced multiple times" {
  run source "${TEST_FIXTURE_PATH}"
  assert_failure
  assert_output "# ERROR: already sourced"
}

@test "prints message" {
  run othertestplugin
  assert_output "hello from othertestplugin 1.0.0"
}

@test "prints message with args" {
  run othertestplugin test
  assert_output "hello from othertestplugin 1.0.0 - test"
}

@test "prints help" {
  run othertestplugin::help
  assert_output "othertestplugin 1.0.0 help"
}

@test "greets" {
  run othertestplugin::greet
  assert_output "greeting from othertestplugin 1.0.0"
}

@test "greets with args" {
  run othertestplugin::greet "test"
  assert_output "greeting test from othertestplugin 1.0.0"
}
