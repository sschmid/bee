setup() {
  load "test-helper.bash"
  _set_beerc
}

teardown() {
  _teardown_test_tmp_dir
}

_prepare_job_logs() {
  _setup_test_tmp_dir
  export BEE_RESOURCES="${TMP_TEST_DIR}"
}

@test "is not executable" {
  assert_file_not_executable "${PROJECT_ROOT}/src/modules/job.bash"
}

@test "shows help when not enough args" {
  run bee job
  assert_output --partial "plugin-based bash automation"

  run bee job "test"
  assert_output --partial "plugin-based bash automation"
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

@test "runs job and succeeds with time" {
  run bee job -t "testjob" echo "test"
  assert_output --partial "(0 seconds)"

  run bee job --time "testjob" echo "test"
  assert_output --partial "(0 seconds)"
}

@test "runs jobs and resets time" {
  run bee --batch "job -t testjob1 sleep 2" "job -t testjob2 sleep 2"
  assert_line --index 0 --partial "(2 seconds)"
  assert_line --index 1 --partial "(2 seconds)"
}

@test "runs job and fails with time" {
  run bee job -t "testjob" not_a_command
  assert_output --partial "(0 seconds)"

  run bee job --time "testjob" not_a_command
  assert_output --partial "(0 seconds)"
}

@test "logs success to logfile" {
  _prepare_job_logs
  run bee job "testjob" echo "test"
  run cat "${TMP_TEST_DIR}/logs/"*
  assert_output "test"
}

@test "uses job title for logfile" {
  _prepare_job_logs
  run bee job "Do some work" echo "test"
  run ls "${TMP_TEST_DIR}/logs"
  assert_output --partial "Do-some-work"
}

@test "logs error to logfile" {
  _prepare_job_logs
  run bee job "testjob" not_a_command
  run cat "${TMP_TEST_DIR}/logs/"*
  assert_output --partial "not_a_command: command not found"
}

@test "runs plugin as job" {
  _prepare_job_logs
  run bee job "testjob" testplugin greet "test"
  run cat "${TMP_TEST_DIR}/logs/"*
  assert_line --index 0 "# testplugin 2.0.0 sourced"
  assert_line --index 1 "greeting test from testplugin 2.0.0"
}
