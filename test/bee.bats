setup() {
  load 'test-helper.bash'
  _set_beerc
}

teardown() {
  _teardown_test_tmp_dir
}

@test "is executable" {
  assert_file_executable "${PROJECT_ROOT}/src/bee"
}

@test "resolves bee system home" {
  _source_bee
  assert_equal "${BEE_SYSTEM_HOME}" "${PROJECT_ROOT}"
}

@test "resolves bee system home and follows symlink" {
  _setup_test_tmp_dir
  ln -s "${PROJECT_ROOT}/src/bee" "${TMP_TEST_DIR}/bee"
  # shellcheck disable=SC1090
  source "${TMP_TEST_DIR}/bee"
  assert_equal "${BEE_SYSTEM_HOME}" "${PROJECT_ROOT}"
}

@test "resolves bee system home and follows multiple symlinks" {
  _setup_test_tmp_dir
  mkdir "${TMP_TEST_DIR}/src" "${TMP_TEST_DIR}/bin"
  ln -s "${PROJECT_ROOT}/src/bee" "${TMP_TEST_DIR}/src/bee"
  ln -s "${TMP_TEST_DIR}/src/bee" "${TMP_TEST_DIR}/bee"
  # shellcheck disable=SC1090
  source "${TMP_TEST_DIR}/bee"
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
  _setup_test_tmp_dir
  _setup_test_bee_repo
  run bee
  assert_line --index 0 "# test bee-run.bash 0.1.0 sourced"
}
