setup() {
  load "test-helper.bash"
}

@test "fails when branch name does not exist" {
  skip "This command uses BEE_SYSTEM_HOME"
  run bee update unknown
  assert_failure
}

@test "completes bee update with branches" {
  skip "Needs branches"
  local expected=(main develop)
  assert_comp "bee update " "${expected[*]}"
}

@test "no completion after branch" {
  assert_comp "bee update main "
}
