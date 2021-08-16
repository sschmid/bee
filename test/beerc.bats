setup() {
  load 'test-helper.bash'
}

@test "loads beerc when specified" {
  _set_test_fixture_beerc
  run bee echo
  assert_line --index 0 "# test beerc sourced"
}

@test "creates default .beerc" {
  export BEE_RC="${BATS_TEST_TMPDIR}/tmp-beerc.bash"
  run bee
  assert_file_exist "${BEE_RC}"
}
