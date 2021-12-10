setup() {
  load 'test-helper.bash'
}

################################################################################
# log echo
################################################################################

@test "logs echo message" {
  run bee bee::log_echo message
  assert_success
  assert_output "message"
}

@test "logs multiple echo messages" {
  run bee bee::log_echo message1 message2 message3
  assert_success
  cat << 'EOF' | assert_output -
message1
message2
message3
EOF
}

@test "doesn't log echo when quiet" {
  run bee --quiet bee::log_echo message
  assert_success
  refute_output
}

#################################################################################
## log
#################################################################################

@test "logs message" {
  run bee bee::log message
  assert_success
  assert_output "${BEE_ICON} message"
}

@test "logs multiple messages" {
  run bee bee::log message1 message2 message3
  assert_success
  cat << EOF | assert_output -
${BEE_ICON} message1
message2
message3
EOF
}

@test "doesn't log when quiet" {
  run bee --quiet bee::log message
  assert_success
  refute_output
}

#################################################################################
## info
#################################################################################

@test "logs info message" {
  run bee bee::log_info message
  assert_success
  cat << EOF | assert_output -
################################################################################
${BEE_ICON} message
################################################################################
EOF
}

@test "logs multiple info messages" {
  run bee bee::log_info message1 message2 message3
  assert_success
  cat << EOF | assert_output -
################################################################################
${BEE_ICON} message1
message2
message3
################################################################################
EOF
}

@test "doesn't log info when quiet" {
  run bee --quiet bee::log_info message
  assert_success
  refute_output
}

#################################################################################
## func
#################################################################################

@test "logs func with message" {
  run bee bee::log_func message
  assert_success
  cat << EOF | assert_output -
################################################################################
${BEE_ICON} bee::run message
################################################################################
EOF
}

@test "logs func with multiple messages" {
  run bee bee::log_func message1 message2 message3
  assert_success
  cat << EOF | assert_output -
################################################################################
${BEE_ICON} bee::run message1
message2
message3
################################################################################
EOF
}

@test "doesn't log func when quiet" {
  run bee --quiet bee::log_func message
  assert_success
  refute_output
}

#################################################################################
## warn
#################################################################################

@test "logs warn message" {
  run bee bee::log_warn message
  assert_success
  assert_output "${BEE_WARN} message"
}

@test "logs multiple warn messages" {
  run bee bee::log_warn message1 message2 message3
  assert_success
  cat << EOF | assert_output -
${BEE_WARN} message1
message2
message3
EOF
}

@test "logs warn message even when quiet" {
  run bee --quiet bee::log_warn message
  assert_success
  assert_output "${BEE_WARN} message"
}

#################################################################################
## error
#################################################################################

@test "logs error message" {
  run bee bee::log_error message
  assert_success
  assert_output "${BEE_ERR} message"
}

@test "logs multiple error messages" {
  run bee bee::log_error message1 message2 message3
  assert_success
  cat << EOF | assert_output -
${BEE_ERR} message1
message2
message3
EOF
}

@test "logs error message even when quiet" {
  run bee --quiet bee::log_error message
  assert_success
  assert_output "${BEE_ERR} message"
}
