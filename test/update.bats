setup() {
  load "test-helper.bash"
}

@test "fails when branch name does not exist" {
  skip "This command uses BEE_SYSTEM_HOME"
  run bee update unknown
  assert_failure
}
