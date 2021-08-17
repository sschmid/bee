setup() {
  load 'test-helper.bash'
  _set_beerc
}

@test "prints bee help" {
  _set_beerc
  run bee -h
  assert_output --partial "plugin-based bash automation"

  run bee --help
  assert_output --partial "plugin-based bash automation"
}

@test "batches multiple commands with args" {
  run bee --batch "echo test1 test2" "echo test3 test4"
  assert_line --index 0 "test1 test2"
  assert_line --index 1 "test3 test4"

  run bee --batch "echo test1 test2" "echo test3 test4"
  assert_line --index 0 "test1 test2"
  assert_line --index 1 "test3 test4"
}

@test "batches multiple commands without args" {
  run bee --batch "echo" "echo test1" "echo" "bee::log_echo test2"
  assert_line --index 0 "test1"
  assert_line --index 1 "test2"
}

@test "runs multiple plugin commands" {
  run bee --batch "testplugin:1.0.0 greet test1" "testplugin:2.0.0 greet test2"
  assert_line --index 0 "# testplugin 1.0.0 sourced"
  assert_line --index 1 "greeting test1 from testplugin 1.0.0"
  assert_line --index 2 "# testplugin 2.0.0 sourced"
  assert_line --index 3 "greeting test2 from testplugin 2.0.0"
}

@test "enable quiet mode" {
  run bee -q bee::log "test"
  refute_output

  run bee --quiet bee::log "test"
  refute_output
}

@test "-- ends options" {
  run bee -- echo "test"
  assert_output "test"

  run bee -q -- echo "test"
  assert_output "test"
}

@test "prints bee help when options only" {
  _set_beerc
  run bee --
  assert_output --partial "plugin-based bash automation"
}

@test "prints version" {
  local bee_version
  bee_version="$(cat "${PROJECT_ROOT}/version.txt")"
  run bee --version
  assert_output "${bee_version}"
}
