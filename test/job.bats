setup() {
  load "test-helper.bash"
  _set_beerc
}

_prepare_job_logs() {
  export BEE_RESOURCES="${BATS_TEST_TMPDIR}"
}

@test "shows help when not enough args" {
  run bee job
  assert_bee_help

  run bee job "test"
  assert_bee_help
}

@test "runs job and succeeds" {
  run bee job "testjob" echo "test"
  assert_success
  assert_output --partial "testjob ${BEE_CHECK_SUCCESS}"
}

@test "runs job and fails" {
  run bee job "testjob" not_a_command
  assert_failure
  assert_output --partial "testjob ${BEE_CHECK_FAIL}"
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
  run cat "${BEE_RESOURCES}/logs/"*
  assert_output "test"
}

@test "uses job title for logfile" {
  _prepare_job_logs
  run bee job "Do some work" echo "test"
  run ls "${BEE_RESOURCES}/logs"
  assert_output --partial "Do-some-work"
}

@test "logs error to logfile" {
  _prepare_job_logs
  run bee job "testjob" not_a_command
  run cat "${BEE_RESOURCES}/logs/"*
  assert_output --partial "not_a_command: command not found"
}

@test "runs job and succeeds verbose" {
  _prepare_job_logs
  run bee --verbose job "testjob" echo "test"

  assert_line --index 0 "testjob"
  assert_line --index 1 "test"
  assert_line --index 2 --partial "testjob"

  run cat "${BEE_RESOURCES}/logs/"*
  assert_output "test"
}

@test "runs job and fails verbose" {
  _prepare_job_logs
  run bee --verbose job "testjob" not_a_command

  assert_line --index 0 "testjob"
  assert_line --index 1 --partial "not_a_command: command not found"

  run cat "${BEE_RESOURCES}/logs/"*
  assert_output --partial "not_a_command: command not found"
}

@test "runs plugin as job" {
  _prepare_job_logs
  run bee job "testjob" testplugin greet "test"
  run cat "${BEE_RESOURCES}/logs/"*
  cat << 'EOF' | assert_output -
# testplugin 2.0.0 sourced
greeting test from testplugin 2.0.0
EOF
}

@test "completes job with -t --time" {
  _source_bee
  local expected=("-t" "--time")
  assert_comp "bee job " "${expected[*]}"
}

@test "no comp for job -t" {
  _source_bee
  assert_comp "bee job -t "
}

@test "no comp for job --time" {
  _source_bee
  assert_comp "bee job --time "
}
