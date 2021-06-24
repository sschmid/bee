setup() {
  load 'test-helper.bash'
}

teardown() {
  _teardown_test_tmp_dir
}

@test "loads beerc when specified" {
  _set_test_fixture_beerc
  run bee echo
  assert_line --index 0 "# test beerc sourced"
}

@test "creates default .beerc" {
  _setup_test_tmp_dir
  export BEE_RC="${TMP_TEST_DIR}/tmp-beerc.bash"
  run bee
  assert_file_exist "${BEE_RC}"
}
