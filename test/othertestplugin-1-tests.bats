setup() {
  load 'test_helper/common-test-setup.bash'
  _common_test_setup
  TESTPLUGIN_PATH="${PROJECT_ROOT}/test/plugins/othertestplugin/1.0.0/othertestplugin.sh"
  source "${TESTPLUGIN_PATH}"
}

@test "is not executable" {
  assert_file_not_executable "${TESTPLUGIN_PATH}"
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

@test "fails on being sourced multiple times" {
  run source "${TESTPLUGIN_PATH}"
  assert_failure
}
