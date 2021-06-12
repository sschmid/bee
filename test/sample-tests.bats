setup() {
  load 'test_helper/common-test-setup.bash'
  _common_test_setup
}

@test "is executable" {
  assert_file_executable "${PROJECT_ROOT}/src/sample.sh"
}
