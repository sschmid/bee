setup() {
  load 'test-helper.bash'
  _set_beerc
  _source_bee
}

################################################################################
# log echo
################################################################################

@test "logs echo message" {
  run _strict bee::log_echo "message"
  assert_output "message"
}

@test "logs multiple echo messages" {
  run _strict bee::log_echo "message1" "message2" "message3"
  cat << 'EOF' | assert_output -
message1
message2
message3
EOF
}

@test "doesn't log echo when quiet" {
  BEE_QUIET=1
  run _strict bee::log_echo "message"
  refute_output
}

#################################################################################
## log
#################################################################################

@test "logs message" {
  run _strict bee::log "message"
  assert_output "🐝 message"
}

@test "logs multiple messages" {
  run _strict bee::log "message1" "message2" "message3"
  cat << 'EOF' | assert_output -
🐝 message1
message2
message3
EOF
}

@test "doesn't log when quiet" {
  BEE_QUIET=1
  run _strict bee::log "message"
  refute_output
}

#################################################################################
## info
#################################################################################

@test "logs info message" {
  run _strict bee::log_info "message"
  cat << 'EOF' | assert_output -
################################################################################
🐝 message
################################################################################
EOF
}

@test "logs multiple info messages" {
  run _strict bee::log_info "message1" "message2" "message3"
  cat << 'EOF' | assert_output -
################################################################################
🐝 message1
message2
message3
################################################################################
EOF
}

@test "doesn't log info when quiet" {
  BEE_QUIET=1
  run _strict bee::log_info "message"
  refute_output
}

#################################################################################
## func
#################################################################################

@test "logs func with message" {
  run _strict bee::log_func "message"
  cat << 'EOF' | assert_output -
################################################################################
🐝 _strict message
################################################################################
EOF
}

@test "logs func with multiple messages" {
  run _strict bee::log_func "message1" "message2" "message3"
  cat << 'EOF' | assert_output -
################################################################################
🐝 _strict message1
message2
message3
################################################################################
EOF
}

@test "doesn't log func when quiet" {
  BEE_QUIET=1
  run _strict bee::log_func "message"
  refute_output
}

#################################################################################
## warn
#################################################################################

@test "logs warn message" {
  run _strict bee::log_warn "message"
  assert_output "${BEE_WARN} message"
}

@test "logs multiple warn messages" {
  run _strict bee::log_warn "message1" "message2" "message3"
  cat << EOF | assert_output -
${BEE_WARN} message1
message2
message3
EOF
}

@test "logs warn message even when quiet" {
  BEE_QUIET=1
  run _strict bee::log_warn "message"
  assert_output "${BEE_WARN} message"
}

#################################################################################
## error
#################################################################################

@test "logs error message" {
  run _strict bee::log_error "message"
  assert_output "${BEE_ERR} message"
}

@test "logs multiple error messages" {
  run _strict bee::log_error "message1" "message2" "message3"
  cat << EOF | assert_output -
${BEE_ERR} message1
message2
message3
EOF
}

@test "logs error message even when quiet" {
  BEE_QUIET=1
  run _strict bee::log_error "message"
  assert_output "${BEE_ERR} message"
}

#################################################################################
## var
#################################################################################

@test "logs var" {
  my_var="test1"
  run _strict bee::env my_var
  assert_output "test1"
}

# shellcheck disable=SC2034
@test "logs var even when quiet" {
  BEE_QUIET=1
  my_var="test2"
  run _strict bee::env my_var
  assert_output "test2"
}
