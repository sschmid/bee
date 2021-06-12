setup() {
  load 'test_helper/common-test-setup.bash'
  _common_test_setup
  TESTPLUGIN_PATH="${PROJECT_ROOT}/test/plugins/testplugin/1.0.0/testplugin.sh"
  source "${TESTPLUGIN_PATH}"
}

@test "is not executable" {
  assert_file_not_executable "${TESTPLUGIN_PATH}"
}

@test "prints testplugin message" {
  run testplugin
  assert_output "hello from testplugin 1.0.0"
}

@test "prints testplugin message with args" {
  run testplugin test
  assert_output "hello from testplugin 1.0.0 - test"
}
