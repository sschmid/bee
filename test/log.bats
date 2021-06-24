setup() {
  load 'test-helper.bash'
  _set_beerc
  _source_bee
}

################################################################################
# log echo
################################################################################

@test "logs echo message" {
  run bee::log_echo "message"
  assert_output "message"
}

@test "logs multiple echo messages" {
  run bee::log_echo "message1" "message2" "message3"
  assert_line --index 0 "message1"
  assert_line --index 1 "message2"
  assert_line --index 2 "message3"
}

@test "doesn't log echo when quiet" {
  BEE_QUIET=1
  run bee::log_echo "message"
  refute_output
}

#################################################################################
## log
#################################################################################

@test "logs message" {
  run bee::log "message"
  assert_output "🐝 message"
}

@test "logs multiple messages" {
  run bee::log "message1" "message2" "message3"
  assert_line --index 0 "🐝 message1"
  assert_line --index 1 "message2"
  assert_line --index 2 "message3"
}

@test "doesn't log when quiet" {
  BEE_QUIET=1
  run bee::log "message"
  refute_output
}

#################################################################################
## info
#################################################################################

@test "logs info message" {
  run bee::log_info "message"
  assert_line --index 0 "################################################################################"
  assert_line --index 1 "🐝 message"
  assert_line --index 2 "################################################################################"
}

@test "logs multiple info messages" {
  run bee::log_info "message1" "message2" "message3"
  assert_line --index 0 "################################################################################"
  assert_line --index 1 "🐝 message1"
  assert_line --index 2 "message2"
  assert_line --index 3 "message3"
  assert_line --index 4 "################################################################################"
}

@test "doesn't log info when quiet" {
  BEE_QUIET=1
  run bee::log_info "message"
  refute_output
}

#################################################################################
## func
#################################################################################

@test "logs func with message" {
  run bee::log_func "message"
  assert_line --index 0 "################################################################################"
  assert_line --index 1 "🐝 run message"
  assert_line --index 2 "################################################################################"
}

@test "logs func with multiple messages" {
  run bee::log_func "message1" "message2" "message3"
  assert_line --index 0 "################################################################################"
  assert_line --index 1 "🐝 run message1"
  assert_line --index 2 "message2"
  assert_line --index 3 "message3"
  assert_line --index 4 "################################################################################"
}

@test "doesn't log func when quiet" {
  BEE_QUIET=1
  run bee::log_func "message"
  refute_output
}

#################################################################################
## warn
#################################################################################

@test "logs warn message" {
  run bee::log_warn "message"
  assert_output "🟠 message"
}

@test "logs multiple warn messages" {
  run bee::log_warn "message1" "message2" "message3"
  assert_line --index 0 "🟠 message1"
  assert_line --index 1 "message2"
  assert_line --index 2 "message3"
}

@test "logs warn message even when quiet" {
  BEE_QUIET=1
  run bee::log_warn "message"
  assert_output "🟠 message"
}

#################################################################################
## error
#################################################################################

@test "logs error message" {
  run bee::log_error "message"
  assert_output "🔴 message"
}

@test "logs multiple error messages" {
  run bee::log_error "message1" "message2" "message3"
  assert_line --index 0 "🔴 message1"
  assert_line --index 1 "message2"
  assert_line --index 2 "message3"
}

@test "logs error message even when quiet" {
  BEE_QUIET=1
  run bee::log_error "message"
  assert_output "🔴 message"
}

#################################################################################
## var
#################################################################################

@test "logs var" {
  my_var="test1"
  run bee::log_var my_var
  assert_output "test1"
}

@test "logs var even when quiet" {
  BEE_QUIET=1
  my_var="test2"
  run bee::log_var my_var
  assert_output "test2"
}
