setup() {
  load 'test_helper/common-test-setup.bash'
  _common_test_setup
  export BEE_PLUGINS_PATH="${PROJECT_ROOT}/test/plugins"
}

@test "is executable" {
  assert_file_executable "${PROJECT_ROOT}/src/bee"
}

@test "prints usage when no args" {
  run bee
  assert_output "usage"
}

@test "runs args" {
  run bee echo "test"
  assert_output "test"
}

@test "resolves latest plugin" {
  run bee bee::resolve_plugin testplugin
  assert_output "${BEE_PLUGINS_PATH}/testplugin/2.0.0/testplugin.sh"
}

@test "resolves plugin with exact version" {
  run bee bee::resolve_plugin testplugin:1.0.0
  assert_output "${BEE_PLUGINS_PATH}/testplugin/1.0.0/testplugin.sh"
}

@test "won't resolve plugin that doesn't exit" {
  run bee bee::resolve_plugin missing
  refute_output
}

@test "won't resolve plugin with exact version that doesn't exit" {
  run bee bee::resolve_plugin missing:1.0.0
  refute_output
}
