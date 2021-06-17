setup() {
  load 'test-helper.bash'
  _source_bee
}

@test "enable quiet mode" {
  run bee::run -q bee::log "test"
  refute_output

  run bee::run --quiet bee::log "test"
  refute_output
}

@test "batches multiple commands with args" {
  run bee::run -b "echo test1 test2" "echo test3 test4"
  assert_line --index 0 "test1 test2"
  assert_line --index 1 "test3 test4"

  run bee::run --batch "echo test1 test2" "echo test3 test4"
  assert_line --index 0 "test1 test2"
  assert_line --index 1 "test3 test4"
}

@test "batches multiple commands without args" {
  run bee::run --batch "echo" "echo test1" "echo" "bee::log_echo test2"
  assert_line --index 0 "test1"
  assert_line --index 1 "test2"
}

@test "runs multiple plugin commands" {
  run bee::run --batch "testplugin:1.0.0 greet test1" "testplugin:2.0.0 greet test2"
  assert_line --index 0 "# testplugin 1.0.0 sourced"
  assert_line --index 1 "greeting test1 from testplugin 1.0.0"
  assert_line --index 2 "# testplugin 2.0.0 sourced"
  assert_line --index 3 "greeting test2 from testplugin 2.0.0"
}
