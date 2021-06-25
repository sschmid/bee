setup() {
  load "test-helper.bash"
  _set_beerc
  MODULE_PATH="${PROJECT_ROOT}/src/modules/bee-update.bash"
  source "${MODULE_PATH}"
}

teardown() {
  _teardown_test_tmp_dir
}

@test "is not executable" {
  assert_file_not_executable "${MODULE_PATH}"
}

@test "shows help when args" {
  run bee update "test"
  assert_output --partial "plugin-based bash automation"
}

# This test would actually pull and update the system bee
#@test "doesn't update specified bee version" {
#  _set_test_beefile
#  _setup_test_tmp_dir
#  _setup_test_bee_repo
#  bee update
#  run bee
#  assert_line --index 0 "# test bee-run.bash 0.1.0 sourced"
#}
