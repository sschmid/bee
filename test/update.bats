setup() {
  load "test-helper.bash"
  _set_beerc
}

@test "shows help when args" {
  run bee update test
  assert_bee_help
}
