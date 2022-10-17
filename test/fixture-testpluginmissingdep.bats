setup() {
  load "test-helper.bash"
  local fixture="fixtures/plugins/testpluginmissingdep/1.0.0/testpluginmissingdep.bash"
  load "${fixture}"
  TEST_FIXTURE_PATH="${BATS_TEST_DIRNAME}/${fixture}"
}

@test "prints message when sourced" {
  run source "${TEST_FIXTURE_PATH}"
  assert_success
  assert_output "# testpluginmissingdep 1.0.0 sourced"
}

@test "doesn't print message when TEST_PLUGIN_QUIET " {
  export TEST_PLUGIN_QUIET=1
  run source "${TEST_FIXTURE_PATH}"
  assert_success
  refute_output
}

@test "prints message" {
  run testpluginmissingdep
  assert_success
  assert_output "hello from testpluginmissingdep 1.0.0"
}

@test "prints message with args" {
  run testpluginmissingdep test
  assert_success
  assert_output "hello from testpluginmissingdep 1.0.0 - test"
}
