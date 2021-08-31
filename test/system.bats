setup() {
  load 'test-helper.bash'
}

_test_dependencies() {
  while read -r dep; do
    echo "# ${dep}"
    if ! command -v "${dep}"; then
      echo "# MISSING ${dep}"
    fi
  done < <(cat "${PROJECT_ROOT}/DEPENDENCIES.md")
}

@test "system has all required dependencies installed" {
  assert_file_exist "${PROJECT_ROOT}/DEPENDENCIES.md"
  run _test_dependencies
  assert_success
  refute_output --partial "MISSING"
}
