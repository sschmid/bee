setup() {
  load "test-helper.bash"
  _set_beerc
  MODULE_PATH="${PROJECT_ROOT}/src/modules/bee-job.sh"
  source "${MODULE_PATH}"
}

teardown() {
  _teardown_test_tmp_dir
}

@test "is not executable" {
  assert_file_not_executable "${MODULE_PATH}"
}

@test "shows help when not enough args" {
  run bee job
  assert_output --partial "bee job"

  run bee job "test"
  assert_output --partial "bee job"
}

@test "runs job and succeeds" {
  run bee job "testjob" echo "test"
  assert_success
  assert_output --partial "testjob ✔"
}

@test "runs job and fails" {
  run bee job "testjob" not_a_command
  assert_failure
  assert_output --partial "testjob ✗"
}

@test "logs success to logfile" {
  _setup_test_tmp_dir
  export BEE_RESOURCES="${TMP_TEST_DIR}"
  run bee job "testjob" echo "test"
  run cat "${TMP_TEST_DIR}/logs/"*
  assert_output "test"
}

@test "logs error to logfile" {
  _setup_test_tmp_dir
  export BEE_RESOURCES="${TMP_TEST_DIR}"
  run bee job "testjob" not_a_command
  run cat "${TMP_TEST_DIR}/logs/"*
  assert_output --partial "not_a_command: command not found"
}

@test "runs plugin as job" {
  _setup_test_tmp_dir
  export BEE_RESOURCES="${TMP_TEST_DIR}"
  run bee job "testjob" testplugin greet "test"
  run cat "${TMP_TEST_DIR}/logs/"*
  assert_line --index 0 "# testplugin 2.0.0 sourced"
  assert_line --index 1 "greeting test from testplugin 2.0.0"
}
