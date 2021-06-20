setup() {
  load 'test-helper.bash'
}

teardown() {
  _teardown_test_tmp_dir
}

@test "loads beerc when specified" {
  _set_test_fixture_beerc
  run bee echo
  assert_output "# test beerc sourced"
}

@test "loads beerc only once" {
  _set_test_fixture_beerc
  _source_bee
  bee::load_beerc
  run bee::load_beerc
  refute_output
}

@test "creates default .beerc" {
  _setup_test_tmp_dir
  BEE_RC="${TMP_TEST_DIR}/tmp-beerc.sh"
  run bee echo
  assert_file_exist "${BEE_RC}"
}
