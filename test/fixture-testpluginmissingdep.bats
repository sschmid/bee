setup() {
  load "test-helper.bash"
  local fixture="fixtures/plugins/testpluginmissingdep/1.0.0/testpluginmissingdep.bash"
  load "${fixture}"
  TEST_FIXTURE_PATH="${BATS_TEST_DIRNAME}/${fixture}"
}

@test "is not executable" {
  assert_file_not_executable "${TEST_FIXTURE_PATH}"
}

@test "prints message when sourced" {
  run source "${TEST_FIXTURE_PATH}"
  assert_output "# testpluginmissingdep 1.0.0 sourced"
}

@test "prints message" {
  run testpluginmissingdep
  assert_output "hello from testpluginmissingdep 1.0.0"
}

@test "prints message with args" {
  run testpluginmissingdep test
  assert_output "hello from testpluginmissingdep 1.0.0 - test"
}

@test "prints deps" {
  run testpluginmissingdep::deps
  cat << 'EOF' | assert_output -
testplugindepsdep:1.0.0
missing:1.0.0
othermissing:1.0.0
EOF
}
