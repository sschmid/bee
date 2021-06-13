setup() {
  load 'test_helper/common-test-setup.bash'
  _common_test_setup
  TESTPLUGIN_PATH="${PROJECT_ROOT}/test/plugins/testplugin/2.0.0/testplugin.sh"
  source "${TESTPLUGIN_PATH}"
}

@test "is not executable" {
  assert_file_not_executable "${TESTPLUGIN_PATH}"
}

@test "prints message" {
  run testplugin
  assert_output "hello from testplugin 2.0.0"
}

@test "prints message with args" {
  run testplugin test
  assert_output "hello from testplugin 2.0.0 - test"
}

@test "prints help" {
  run testplugin::help
  assert_output "testplugin 2.0.0 help"
}

@test "greets" {
  run testplugin::greet
  assert_output "greeting from testplugin 2.0.0"
}

@test "greets with args" {
  run testplugin::greet "test"
  assert_output "greeting test from testplugin 2.0.0"
}

@test "fails on being sourced multiple times" {
  run source "${TESTPLUGIN_PATH}"
  assert_failure
}
