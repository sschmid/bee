setup() {
  load 'test-helper.bash'
  _set_beerc
  _set_test_modules
}

@test "is not executable" {
  assert_file_not_executable "${PROJECT_ROOT}/src/bee-run.bash"
}

@test "prints bee help when no args" {
  _unset_test_modules
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

@test "runs bee module" {
  run bee testmodule
  assert_line --index 0 "# testmodule sourced"
  assert_line --index 1 "hello from testmodule"
}

@test "runs bee module with args" {
  run bee testmodule "test"
  assert_line --index 0 "# testmodule sourced"
  assert_line --index 1 "hello from testmodule - test"
}

@test "runs bee plugin" {
  run bee testplugin
  assert_line --index 0 "# testplugin 2.0.0 sourced"
  assert_line --index 1 "testplugin 2.0.0 help"
}

@test "runs bee plugin with args" {
  run bee testplugin greet "test"
  assert_line --index 0 "# testplugin 2.0.0 sourced"
  assert_line --index 1 "greeting test from testplugin 2.0.0"
}

@test "runs bee plugin with exact version" {
  run bee testplugin:1.0.0
  assert_line --index 0 "# testplugin 1.0.0 sourced"
  assert_line --index 1 "testplugin 1.0.0 help"
}

@test "runs bee plugin with exact version with args" {
  run bee testplugin:1.0.0 greet "test"
  assert_line --index 0 "# testplugin 1.0.0 sourced"
  assert_line --index 1 "greeting test from testplugin 1.0.0"
}
