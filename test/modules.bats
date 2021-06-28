setup() {
  load 'test-helper.bash'
  _set_test_beerc
  _source_bee
}

@test "loads module" {
  run bee::load_module testmodule
  assert_output "# testmodule sourced"

  bee::load_module testmodule
  assert_equal "${BEE_LOAD_MODULE_NAME}" "testmodule"
}

@test "loads another module" {
  bee::load_module testmodule
  run bee::load_module othertestmodule
  assert_output "# othertestmodule sourced"

  bee::load_module othertestmodule
  assert_equal "${BEE_LOAD_MODULE_NAME}" "othertestmodule"
}

@test "doesn't load unknown module" {
  run bee::load_module unknown
  assert_success
  refute_output

  bee::load_module unknown
  assert_equal "${BEE_LOAD_MODULE_NAME}" ""
}

@test "loads module only once" {
  bee::load_module testmodule
  run bee::load_module testmodule
  assert_success
  refute_output
}

@test "loads unknown module only once" {
  bee::load_module unknown
  run bee::load_module unknown
  assert_success
  refute_output
}

@test "caches module" {
  bee::load_module testmodule
  bee::load_module othertestmodule
  run bee::load_module testmodule
  refute_output

  bee::load_module testmodule
  assert_equal "${BEE_LOAD_MODULE_NAME}" "testmodule"
}

@test "caches unknown module" {
  bee::load_module testmodule
  bee::load_module unknown
  bee::load_module testmodule
  run bee::load_module unknown
  assert_success
  refute_output

  bee::load_module unknown
  assert_equal "${BEE_LOAD_MODULE_NAME}" ""
}

@test "runs module" {
  bee::load_module testmodule
  run bee::run_module testmodule
  assert_output "hello from testmodule"
}

@test "runs module with args" {
  bee::load_module testmodule
  run bee::run_module testmodule "test"
  assert_output "hello from testmodule - test"
}
