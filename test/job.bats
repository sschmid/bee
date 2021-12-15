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

  run bee job test
  assert_bee_help
}

@test "runs job and succeeds" {
  run bee job testjob echo test
  assert_success
  assert_output  "##Stestjob ${BEE_CHECK_SUCCESS}#"
}

@test "runs job and fails" {
  run bee job testjob not_a_command
  assert_failure
  assert_output "##Etestjob ${BEE_CHECK_FAIL}#"
}

@test "runs job and succeeds with time" {
  run bee job --time testjob echo test
  assert_success
  assert_output "##Stestjob ${BEE_CHECK_SUCCESS} (0 seconds)#"
}

@test "runs jobs and resets time" {
  run bee --batch "job --time testjob1 sleep 2" "job --time testjob2 sleep 2"
  assert_success
  cat << EOF | assert_output -
##Stestjob1 ${BEE_CHECK_SUCCESS} (2 seconds)#
##Stestjob2 ${BEE_CHECK_SUCCESS} (2 seconds)#
EOF
}

@test "runs job and fails with time" {
  run bee job --time testjob not_a_command
  assert_failure
  assert_output "##Etestjob ${BEE_CHECK_FAIL} (0 seconds)#"
}

@test "logs success to logfile" {
  _prepare_job_logs
  run bee job --logfile testjob echo test
  run cat "${BEE_RESOURCES}/logs/"*
  assert_output "test"
}

@test "uses job title for logfile" {
  _prepare_job_logs
  run bee job --logfile "test job" echo test
  run ls "${BEE_RESOURCES}/logs"
  assert_output --partial "test-job"
}

@test "logs error to logfile" {
  _prepare_job_logs
  run bee job --logfile testjob not_a_command
  run cat "${BEE_RESOURCES}/logs/"*
  assert_output --partial "not_a_command: command not found"
}

@test "runs job and succeeds verbose" {
  _prepare_job_logs
  run bee --verbose job --logfile testjob echo test

  cat << EOF | assert_output -
testjob
test
#Stestjob ${BEE_CHECK_SUCCESS}#
EOF

  run cat "${BEE_RESOURCES}/logs/"*
  assert_output "test"
}

@test "runs job and fails verbose" {
  _prepare_job_logs
  run bee --verbose job --logfile testjob not_a_command

  assert_line --index 0 "testjob"
  assert_line --index 1 --partial "not_a_command: command not found"

  run cat "${BEE_RESOURCES}/logs/"*
  assert_output --partial "not_a_command: command not found"
}

@test "runs plugin as job" {
  _prepare_job_logs
  run bee job --logfile testjob testplugin greet test
  run cat "${BEE_RESOURCES}/logs/"*
  cat << 'EOF' | assert_output -
# testplugin 2.0.0 sourced
greeting test from testplugin 2.0.0
EOF
}

@test "completes bee job with --logfile --time" {
  local expected=(--logfile --time)
  assert_comp "bee job " "${expected[*]}"
}

@test "completes bee job --logfile with --time" {
  local expected=(--time)
  assert_comp "bee job --logfile " "${expected[*]}"
}

@test "completes bee job --time with --logfile" {
  local expected=(--logfile)
  assert_comp "bee job --time " "${expected[*]}"
}

@test "no comp for bee job --logfile --time" {
  assert_comp "bee job --logfile --time "
}
