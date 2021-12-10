setup() {
  load "test-helper.bash"
  _set_beerc
  export BEE_WIKI="test wiki"
  export BEE_OSTYPE="generic"
}

@test "shows help when args" {
  run bee wiki test
  assert_bee_help
}

@test "opens wiki" {
  run bee wiki
  assert_success
  assert_output "test wiki"
}
