setup() {
  load "test-helper.bash"
  _set_beerc
  _set_test_modules
  _source_bee
  MODULE_PATH="${PROJECT_ROOT}/src/modules/help.bash"
}

@test "is not executable" {
  assert_file_not_executable "${MODULE_PATH}"
}

@test "prints entries" {
  # shellcheck disable=SC1090
  source "${MODULE_PATH}"
  run _strict bee::help::print_entries
  assert_line --index 0 -e '^[[:space:]]*testmodule[[:space:]]+help[[:space:]]1'
  assert_line --index 1 -e '^[[:space:]]*testmodule[[:space:]]test[[:space:]]+help[[:space:]]2'
}
