setup() {
  load 'test-helper.bash'
}

@test "loads beerc when specified" {
  _set_beerc_fixture
  run bee :
  assert_output "# test beerc sourced"
}

@test "creates default .beerc" {
  export BEE_RC="${BATS_TEST_TMPDIR}/beerc.bash"
  run bee
  assert_file_exist "${BEE_RC}"
}
