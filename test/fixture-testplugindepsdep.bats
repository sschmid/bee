setup() {
  load "test-helper.bash"
  local fixture="fixtures/plugins/testplugindepsdep/1.0.0/testplugindepsdep.bash"
  load "${fixture}"
  TEST_FIXTURE_PATH="${BATS_TEST_DIRNAME}/${fixture}"
}

@test "is not executable" {
  assert_file_not_executable "${TEST_FIXTURE_PATH}"
}

@test "prints message when sourced" {
  run source "${TEST_FIXTURE_PATH}"
  assert_success
  assert_output "# testplugindepsdep 1.0.0 sourced"
}

@test "doesn't print message when TESTPLUGIN_QUIET " {
  export TESTPLUGIN_QUIET=1
  run source "${TEST_FIXTURE_PATH}"
  assert_success
  refute_output
}

@test "prints message" {
  run testplugindepsdep
  assert_success
  assert_output "hello from testplugindepsdep 1.0.0"
}

@test "prints message with args" {
  run testplugindepsdep test
  assert_success
  assert_output "hello from testplugindepsdep 1.0.0 - test"
}

@test "prints deps" {
  run testplugindepsdep::deps
  assert_success
  cat << 'EOF' | assert_output -
testplugindeps:1.0.0
testplugin:1.0.0
EOF
}

@test "fails to call deps" {
  run testplugindepsdep::greet
  assert_failure
  assert_output --partial "greeting from testplugindepsdep 1.0.0"
  assert_output --partial "testplugindeps::greet: command not found"
  assert_output --partial "othertestplugin::greet: command not found"
}
