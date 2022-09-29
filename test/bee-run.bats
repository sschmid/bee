setup() {
  load 'test-helper.bash'
  _set_beerc_with 'bee::secrets() { echo "bee-secrets $@"; }'
  export TEST_PLUGIN_QUIET=1
}

@test "is not executable" {
  assert_file_not_executable "${PROJECT_ROOT}/src/bee-run.bash"
}

@test "prints bee help when no args" {
  run bee
  assert_bee_help
}

@test "runs args" {
  run bee echo test
  assert_success
  assert_output "test"
}

@test "runs internal bee command" {
  run bee bee::log_echo test
  assert_success
  assert_output "test"
}

@test "runs bee plugin" {
  run bee --quiet testplugin
  assert_success
  assert_output "testplugin 2.0.0 help"
}

@test "runs bee plugin with args" {
  run bee --quiet testplugin greet test
  assert_success
  cat << EOF | assert_output -
bee-secrets testplugin greet test
greeting test from testplugin 2.0.0
EOF

}

@test "runs bee plugin with exact version" {
  run bee --quiet testplugin:1.0.0
  assert_success
  assert_output "testplugin 1.0.0 help"
}

@test "runs bee plugin with exact version with args" {
  run bee --quiet testplugin:1.0.0 greet test
  assert_success
  cat << EOF | assert_output -
bee-secrets testplugin greet test
greeting test from testplugin 1.0.0
EOF
}
