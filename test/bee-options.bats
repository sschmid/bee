setup() {
  load 'test-helper.bash'
  _set_beerc
}

@test "prints bee help" {
  run bee -h
  assert_bee_help

  run bee --help
  assert_bee_help
}

@test "batches multiple commands with args" {
  run bee --batch "echo test1 test2" "echo test3 test4"
  cat << 'EOF' | assert_output -
test1 test2
test3 test4
EOF

  run bee --batch "echo test1 test2" "echo test3 test4"
  cat << 'EOF' | assert_output -
test1 test2
test3 test4
EOF
}

@test "batches multiple commands without args" {
  run bee --batch "echo" "echo test1" "echo" "bee::log_echo test2"
  cat << 'EOF' | assert_output -

test1

test2
EOF
}

@test "runs multiple plugin commands" {
  run bee -q --batch "testplugin:1.0.0 greet test1" "testplugin:2.0.0 greet test2"
  cat << 'EOF' | assert_output -
# testplugin 1.0.0 sourced
greeting test1 from testplugin 1.0.0
# testplugin 2.0.0 sourced
greeting test2 from testplugin 2.0.0
EOF
}

@test "enable quiet mode" {
  run bee -q bee::log "test"
  refute_output

  run bee --quiet bee::log "test"
  refute_output
}

@test "enable verbose mode" {
  _source_bee
  run _strict bee::run -v bee::env BEE_VERBOSE
  assert_output "1"

  run _strict bee::run -v bee::env BEE_VERBOSE
  assert_output "1"
}

@test "-- ends options" {
  run bee -- echo "test"
  assert_output "test"

  run bee -q -- echo "test"
  assert_output "test"
}

@test "prints bee help when options only" {
  run bee --
  assert_bee_help
}

@test "prints version" {
  run bee --version
  assert_output "$(cat "${PROJECT_ROOT}/version.txt")"
}
