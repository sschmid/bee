setup() {
  load 'test-helper.bash'
  _set_test_beerc
  _source_bee
}

_test_exit() {
  echo "test exit $*"
}

@test "adds exit trap with status" {
  bee::add_exit_trap _test_exit
  run _strict bee::run :
  assert_success
  assert_output "test exit 0"
}

@test "adds exit trap with error status" {
  bee::add_exit_trap _test_exit
  run _strict bee::run not_a_command
  assert_failure
  assert_output --partial "test exit 127"
}

@test "removes exit trap" {
  bee::add_exit_trap _test_exit
  bee::remove_exit_trap _test_exit
  run _strict bee::run :
  refute_output
}

@test "runs args in internal mode" {
  run bee echo "test"
  assert_output "test"
}

@test "runs module in internal mode" {
  run bee testmodule
  assert_line --index 0 "# testmodule sourced"
  assert_line --index 1 "hello from testmodule"
}

@test "fails in internal mode" {
  run bee not_a_command
  assert_output --partial "not_a_command: command not found"
}

@test "runs plugin in plugin mode" {
  run bee testplugin
  assert_line --index 0 "# testplugin 2.0.0 sourced"
  assert_line --index 1 "testplugin 2.0.0 help"
  assert_line --partial --index 2 "🐝 bzzzz"
}

@test "fails in plugin mode" {
  run bee testplugin not_a_command
  assert_line --index 0 "# testplugin 2.0.0 sourced"
  assert_line --partial --index 1 "testplugin::not_a_command: command not found"
  assert_line --partial --index 2 "🔴 bzzzz 127"
}

@test "runs quiet in plugin mode" {
  run bee --quiet testplugin
  assert_line --index 0 "# testplugin 2.0.0 sourced"
  assert_line --index 1 "testplugin 2.0.0 help"
  refute_output --partial "bzzzz"
}

@test "fails quiet in plugin mode" {
  run bee --quiet testplugin not_a_command
  assert_line --index 0 "# testplugin 2.0.0 sourced"
  assert_line --partial --index 1 "testplugin::not_a_command: command not found"
  refute_output --partial "bzzzz"
}
