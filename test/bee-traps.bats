setup() {
  load 'test-helper.bash'
  _set_beerc
}

_test_exit() { echo "test exit $*"; }
export -f _test_exit

@test "adds exit trap with status" {
  run bee bee::add_exit_trap _test_exit
  assert_success
  assert_output "test exit 0"
}

@test "adds exit trap with error status" {
  run -127 bee --batch \
    "bee::add_exit_trap _test_exit" \
    "not_a_command"
  assert_failure
  assert_output --partial "test exit 127"
}

@test "removes exit trap" {
  run bee --batch \
    "bee::add_exit_trap _test_exit" \
    "bee::remove_exit_trap _test_exit"
  assert_success
  refute_output
}

@test "runs args in internal mode" {
  run bee echo test
  assert_success
  assert_output "test"
}

@test "fails in internal mode" {
  run -127 bee not_a_command
  assert_failure
  assert_output --partial "not_a_command: command not found"
}

@test "runs plugin in plugin mode" {
  run bee testplugin
  assert_success
  cat << EOF | assert_output -
# testplugin 2.0.0 sourced
testplugin 2.0.0 help
${BEE_ICON} bzzzz (0 seconds)
EOF
}

@test "fails in plugin mode" {
  run -127 bee testplugin not_a_command
  assert_failure
  assert_line --index 0 "# testplugin 2.0.0 sourced"
  assert_line --partial --index 1 "testplugin::not_a_command: command not found"
  assert_line --partial --index 2 "${BEE_ERR} bzzzz 127"
}

@test "runs quiet in plugin mode" {
  run bee --quiet testplugin
  assert_success
  cat << 'EOF' | assert_output -
# testplugin 2.0.0 sourced
testplugin 2.0.0 help
EOF
}

@test "fails quiet in plugin mode" {
  run -127 bee --quiet testplugin not_a_command
  assert_failure
  assert_line --index 0 "# testplugin 2.0.0 sourced"
  assert_line --partial --index 1 "testplugin::not_a_command: command not found"
  refute_output --partial "bzzzz"
}
