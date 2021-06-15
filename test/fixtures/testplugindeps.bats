setup() {
  load "test-helper.bash"
  local fixture="plugins/testplugindeps/1.0.0/testplugindeps.sh"
  load "${fixture}"
  TEST_FIXTURE_PATH="${BATS_TEST_DIRNAME}/${fixture}"
}

@test "is not executable" {
  assert_file_not_executable "${TEST_FIXTURE_PATH}"
}

@test "prints message when sourced" {
  run source "${TEST_FIXTURE_PATH}"
  assert_output "# testplugindeps 1.0.0 sourced"
}

@test "prints message" {
  run testplugindeps
  assert_output "hello from testplugindeps 1.0.0"
}

@test "prints message with args" {
  run testplugindeps test
  assert_output "hello from testplugindeps 1.0.0 - test"
}

@test "prints deps" {
  run testplugindeps::deps
  assert_line --index 0 "testplugin:1.0.0"
  assert_line --index 1 "othertestplugin:1.0.0"
}

@test "fails to call deps" {
  run testplugindeps::greet
  assert_output --partial "greeting from testplugindeps 1.0.0"
  assert_failure
}
