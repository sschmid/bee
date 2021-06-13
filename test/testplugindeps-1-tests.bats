setup() {
  load 'test_helper/common-test-setup.bash'
  _common_test_setup
  TESTPLUGIN_PATH="${PROJECT_ROOT}/test/plugins/testplugindeps/1.0.0/testplugindeps.sh"
  source "${TESTPLUGIN_PATH}"
}

@test "is not executable" {
  assert_file_not_executable "${TESTPLUGIN_PATH}"
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
