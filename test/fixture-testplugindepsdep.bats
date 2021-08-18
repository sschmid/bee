setup() {
  load "test-helper.bash"
  local fixture="fixtures/plugins/testplugindepsdep/1.0.0/testplugindepsdep.bash"
  load "${fixture}"
  TEST_FIXTURE_PATH="${BATS_TEST_DIRNAME}/${fixture}"
}

@test "is not executable" {
  assert_file_not_executable "${TEST_FIXTURE_PATH}"
}

@test "prints message when sourced" {
  run source "${TEST_FIXTURE_PATH}"
  assert_output "# testplugindepsdep 1.0.0 sourced"
}

@test "prints message" {
  run testplugindepsdep
  assert_output "hello from testplugindepsdep 1.0.0"
}

@test "prints message with args" {
  run testplugindepsdep test
  assert_output "hello from testplugindepsdep 1.0.0 - test"
}

@test "prints deps" {
  run testplugindepsdep::deps
  assert_line --index 0 "testplugindeps:1.0.0"
  assert_line --index 1 "testplugin:1.0.0"
}

@test "fails to call deps" {
  run testplugindepsdep::greet
  assert_output --partial "greeting from testplugindepsdep 1.0.0"
  assert_failure
}
