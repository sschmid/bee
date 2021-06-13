setup() {
  load 'test_helper/common-test-setup.bash'
  _common_test_setup
  TESTPLUGIN_VERSION="2.0.0"
  TESTPLUGIN_PATH="${PROJECT_ROOT}/test/plugins/testplugin/${TESTPLUGIN_VERSION}/testplugin.sh"
  source "${TESTPLUGIN_PATH}"
}

@test "is not executable" {
  assert_file_not_executable "${TESTPLUGIN_PATH}"
}

@test "prints message" {
  run testplugin
  assert_output "hello from testplugin ${TESTPLUGIN_VERSION}"
}

@test "prints message with args" {
  run testplugin test
  assert_output "hello from testplugin ${TESTPLUGIN_VERSION} - test"
}

@test "prints help" {
  run testplugin::help
  assert_output "testplugin ${TESTPLUGIN_VERSION} help"
}

@test "greets" {
  run testplugin::greet
  assert_output "greeting from testplugin ${TESTPLUGIN_VERSION}"
}

@test "greets with args" {
  run testplugin::greet "test"
  assert_output "greeting test from testplugin ${TESTPLUGIN_VERSION}"
}
