setup() {
  load 'test_helper/common-test-setup.bash'
  _common_test_setup
  TESTPLUGIN_PATH="${PROJECT_ROOT}/test/plugins/testplugindepsdep/1.0.0/testplugindepsdep.sh"
  source "${TESTPLUGIN_PATH}"
}

@test "is not executable" {
  assert_file_not_executable "${TESTPLUGIN_PATH}"
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
}

@test "fails to call deps" {
  run testplugindepsdep::greet
  assert_output --partial "greeting from testplugindepsdep 1.0.0"
  assert_failure
}
