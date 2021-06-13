setup() {
  load 'test_helper/common-test-setup.bash'
  _common_test_setup
  export BEE_RC="${PROJECT_ROOT}/test/test-beerc.sh"
}

################################################################################
# log echo
################################################################################

@test "logs echo message" {
  run bee bee::log_echo "message"
  assert_output --partial "message"
}

@test "logs multiple echo messages" {
  run bee bee::log_echo "message1" "message2" "message3"
  assert_output --partial "message1"
  assert_output --partial "message2"
  assert_output --partial "message3"
}

@test "logs echo quiet" {
  run bee -q bee::log_echo "message"
  run bee --quiet bee::log_echo "message"
  refute_output
}

################################################################################
# log
################################################################################

@test "logs message" {
  run bee bee::log "message"
  assert_output --partial "message"
}

@test "logs multiple messages" {
  run bee bee::log "message1" "message2" "message3"
  assert_output --partial "message1"
  assert_output --partial "message2"
  assert_output --partial "message3"
}

@test "logs quiet" {
  run bee -q bee::log "message"
  run bee --quiet bee::log "message"
  refute_output
}

################################################################################
# info
################################################################################

@test "logs info message" {
  run bee bee::log_info "message"
  assert_output --partial "message"
}

@test "logs multiple info messages" {
  run bee bee::log_info "message1" "message2" "message3"
  assert_output --partial "message1"
  assert_output --partial "message2"
  assert_output --partial "message3"
}

@test "logs info quiet" {
  run bee -q bee::log_info "message"
  run bee --quiet bee::log_info "message"
  refute_output
}

################################################################################
# func
################################################################################

@test "logs func with message" {
  run bee bee::log_func "message"
  assert_output --partial "message"
}

@test "logs func with multiple messages" {
  run bee bee::log_func "message1" "message2" "message3"
  assert_output --partial "message1"
  assert_output --partial "message2"
  assert_output --partial "message3"
}

@test "logs func quiet" {
  run bee -q bee::log_func "message"
  run bee --quiet bee::log_func "message"
  refute_output
}

################################################################################
# warn
################################################################################

@test "logs warn message" {
  run bee bee::log_warn "message"
  assert_output --partial "message"
}

@test "logs multiple warn messages" {
  run bee bee::log_warn "message1" "message2" "message3"
  assert_output --partial "message1"
  assert_output --partial "message2"
  assert_output --partial "message3"
}

################################################################################
# error
################################################################################

@test "logs error message" {
  run bee bee::log_error "message"
  assert_output --partial "message"
}

@test "logs multiple error messages" {
  run bee bee::log_error "message1" "message2" "message3"
  assert_output --partial "message1"
  assert_output --partial "message2"
  assert_output --partial "message3"
}
