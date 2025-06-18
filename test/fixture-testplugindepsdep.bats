setup() {
  load 'test-helper'
  _common_setup
  local fixture="fixtures/plugins/plugin_with_deps_on_deps/1.0.0/plugin_with_deps_on_deps.bash"
  load "${fixture}"
  TEST_FIXTURE_PATH="${BATS_TEST_DIRNAME}/${fixture}"
}

@test "prints message when sourced" {
  run source "${TEST_FIXTURE_PATH}"
  assert_success
  assert_output "# plugin_with_deps_on_deps 1.0.0 sourced"
}

@test "doesn't print message when TEST_PLUGIN_QUIET " {
  export TEST_PLUGIN_QUIET=1
  run source "${TEST_FIXTURE_PATH}"
  assert_success
  refute_output
}

@test "prints message" {
  run plugin_with_deps_on_deps
  assert_success
  assert_output "hello from plugin_with_deps_on_deps 1.0.0"
}

@test "prints message with args" {
  run plugin_with_deps_on_deps test
  assert_success
  assert_output "hello from plugin_with_deps_on_deps 1.0.0 - test"
}

@test "fails to call deps" {
  run -127 plugin_with_deps_on_deps::greet
  assert_failure
  assert_output --partial "greeting from plugin_with_deps_on_deps 1.0.0"
  assert_output --partial "plugin_with_deps::greet: command not found"
  assert_output --partial "plugin_2::greet: command not found"
}
