setup() {
  load 'test-helper.bash'
  _set_beerc
}

@test "prints bee help" {
  run bee --help
  assert_bee_help
}

@test "enable quiet mode" {
  run bee --quiet bee::log test
  assert_success
  refute_output
}

@test "enable verbose mode" {
  run bee env BEE_VERBOSE
  assert_success
  assert_output "0"

  run bee --verbose env BEE_VERBOSE
  assert_success
  assert_output "1"
}

@test "batches multiple commands with args" {
  run bee --batch "echo test1 test2" "echo test3 test4"
  assert_success
  cat << 'EOF' | assert_output -
test1 test2
test3 test4
EOF
}

@test "batches multiple commands without args" {
  run bee --batch "echo" "echo test1" "echo" "bee::log_echo test2"
  assert_success
  cat << 'EOF' | assert_output -

test1

test2
EOF
}

@test "batches failing commands without args" {
  run bee --batch --allow-fail "unknown" "echo test"
  assert_success
  assert_output --partial "test"
}

@test "batches failing commands with args" {
  run bee --batch --allow-fail "return 1" "echo test"
  assert_success
  assert_output --partial "test"
}

@test "runs multiple plugin commands" {
  run bee --quiet --batch "testplugin:1.0.0 greet test1" "testplugin:2.0.0 greet test2"
  assert_success
cat << 'EOF' | assert_output -
# testplugin 1.0.0 sourced
greeting test1 from testplugin 1.0.0
# testplugin 2.0.0 sourced
greeting test2 from testplugin 2.0.0
EOF
}

@test "-- ends options" {
  run bee -- echo test
  assert_success
  assert_output "test"

  run bee --quiet -- echo test
  assert_success
  assert_output "test"
}

@test "prints bee help when options only" {
  run bee --
  assert_bee_help
}

@test "completes --batch with --allow-fail" {
  _set_beerc_with 'BEE_PLUGINS_PATHS=(unknown)'
  local expected=(--allow-fail --help --quiet --verbose cache env hash hubs info install job lint new plugins pull res update version wiki)
  assert_comp "bee --batch " "${expected[*]}"
}

@test "completes --batch --allow-fail with commands" {
  _set_beerc_with 'BEE_PLUGINS_PATHS=(unknown)'
  local expected=(--help --quiet --verbose cache env hash hubs info install job lint new plugins pull res update version wiki)
  assert_comp "bee --batch --allow-fail " "${expected[*]}"
}
