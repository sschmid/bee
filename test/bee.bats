setup() {
  load 'test-helper.bash'
  _set_beerc
}

teardown() {
  _teardown_test_tmp_dir
}

@test "is executable" {
  assert_file_executable "${PROJECT_ROOT}/src/bee"
}

@test "sources bee-run.bash" {
  run bee
  assert_output --partial "plugin-based bash automation"
}

@test "sources beefile" {
  _set_test_fixture_beefile
  run bee
  assert_line --index 0 "# test beefile sourced"
}

@test "installs specified bee version" {
  _set_test_beefile
  _setup_test_tmp_dir
  _setup_test_bee_repo
  run bee
  assert_line --index 0 "# test bee-run.bash 0.1.0 sourced"
}
