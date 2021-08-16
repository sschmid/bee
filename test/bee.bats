setup() {
  load 'test-helper.bash'
  _set_beerc
}

@test "is executable" {
  assert_file_executable "${PROJECT_ROOT}/src/bee"
}

@test "resolves bee system home" {
  _source_bee
  assert_equal "${BEE_SYSTEM_HOME}" "${PROJECT_ROOT}"
}

@test "resolves bee system home and follows symlink" {
  ln -s "${PROJECT_ROOT}/src/bee" "${BATS_TEST_TMPDIR}/bee"
  # shellcheck disable=SC1090,SC1091
  source "${BATS_TEST_TMPDIR}/bee"
  assert_equal "${BEE_SYSTEM_HOME}" "${PROJECT_ROOT}"
}

@test "resolves bee system home and follows multiple symlinks" {
  mkdir "${BATS_TEST_TMPDIR}/src" "${BATS_TEST_TMPDIR}/bin"
  ln -s "${PROJECT_ROOT}/src/bee" "${BATS_TEST_TMPDIR}/src/bee"
  ln -s "${BATS_TEST_TMPDIR}/src/bee" "${BATS_TEST_TMPDIR}/bee"
  # shellcheck disable=SC1090,SC1091
  source "${BATS_TEST_TMPDIR}/bee"
  assert_equal "${BEE_SYSTEM_HOME}" "${PROJECT_ROOT}"
}

@test "sources bee-run.bash" {
  run bee
  assert_output --partial "plugin-based bash automation"
}

@test "sources beefile" {
  _set_test_fixture_beefile
  run bee
  assert_line --index 0 "# test beefile sourced"
}

@test "installs specified bee version" {
  _set_test_beefile
  _setup_test_bee_repo
  run bee
  assert_line --index 0 "# test bee-run.bash 0.1.0 sourced"
}
