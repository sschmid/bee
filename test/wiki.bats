setup() {
  load "test-helper.bash"
  export BEE_WIKI="test wiki"
}

@test "shows help when args" {
  run bee wiki test
  assert_failure
  assert_bee_help
}

@test "opens wiki" {
  run bee wiki
  assert_success
  assert_output "test wiki"
}
