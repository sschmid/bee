setup() {
  load 'test_helper/common-test-setup.bash'
  _common_test_setup
  TESTPLUGIN_PATH="${PROJECT_ROOT}/test/plugins/testpluginmissingdep/1.0.0/testpluginmissingdep.sh"
  source "${TESTPLUGIN_PATH}"
}

@test "is not executable" {
  assert_file_not_executable "${TESTPLUGIN_PATH}"
}

@test "prints message" {
  run testpluginmissingdep
  assert_output "hello from testpluginmissingdep 1.0.0"
}

@test "prints message with args" {
  run testpluginmissingdep test
  assert_output "hello from testpluginmissingdep 1.0.0 - test"
}

@test "prints deps" {
  run testpluginmissingdep::deps
  assert_line --index 0 "testplugin:1.0.0"
  assert_line --index 1 "missing:1.0.0"
  assert_line --index 2 "missing:2.0.0"
}

@test "fails to call deps" {
  run testpluginmissingdep::greet
  assert_output --partial "greeting from testpluginmissingdep 1.0.0"
}
