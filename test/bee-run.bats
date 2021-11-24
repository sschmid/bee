setup() {
  load 'test-helper.bash'
  _set_beerc
}

@test "is not executable" {
  assert_file_not_executable "${PROJECT_ROOT}/src/bee-run.bash"
}

@test "prints bee help when no args" {
  run bee
  assert_bee_help
}

@test "runs args" {
  run bee echo "test"
  assert_output "test"
}

@test "runs internal bee command" {
  run bee bee::log_echo "test"
  assert_output "test"
}

@test "runs bee plugin" {
  run bee -q testplugin
  cat << 'EOF' | assert_output -
# testplugin 2.0.0 sourced
testplugin 2.0.0 help
EOF
}

@test "runs bee plugin with args" {
  run bee -q testplugin greet "test"
  cat << 'EOF' | assert_output -
# testplugin 2.0.0 sourced
greeting test from testplugin 2.0.0
EOF
}

@test "runs bee plugin with exact version" {
  run bee -q testplugin:1.0.0
  cat << 'EOF' | assert_output -
# testplugin 1.0.0 sourced
testplugin 1.0.0 help
EOF
}

@test "runs bee plugin with exact version with args" {
  run bee -q testplugin:1.0.0 greet "test"
  cat << 'EOF' | assert_output -
# testplugin 1.0.0 sourced
greeting test from testplugin 1.0.0
EOF
}
