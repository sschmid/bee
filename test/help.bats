setup() {
  load "test-helper.bash"
  _set_test_beerc
  MODULE_PATH="${PROJECT_ROOT}/src/modules/bee-help.bash"
  # shellcheck disable=SC1090
  source "${BEE_RC}"
  # shellcheck disable=SC1090
  source "${MODULE_PATH}"
}

@test "is not executable" {
  assert_file_not_executable "${MODULE_PATH}"
}

@test "prints entries" {
  run bee::help::print_entries
  assert_output "  testmodule    help"
}
