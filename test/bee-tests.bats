setup() {
  load 'test_helper/common-test-setup.bash'
  _common_test_setup
  export BEE_RC="${PROJECT_ROOT}/test/test-beerc.sh"
  _bee_plugins_path="${PROJECT_ROOT}/test/plugins"
}

teardown() {
  _delete_test_tmp_dir
}

@test "is executable" {
  assert_file_executable "${PROJECT_ROOT}/src/bee"
}

@test "prints usage when no args" {
  run bee
  assert_output "usage"
}

@test "runs command" {
  run bee echo "test"
  assert_output "test"
}

@test "creates default .beerc" {
  _create_test_tmp_dir
  BEE_RC="${TMP_DIR}/tmp-beerc.sh"
  run bee echo "test"
  assert_file_exist "${BEE_RC}"
}

@test "logs variable" {
  run bee bee::log_var BEE_PLUGINS_PATH
  assert_output "${_bee_plugins_path}"
}

@test "runs multiple commands" {
  run bee batch "echo test1" "echo test2"
  assert_line --index 0 "test1"
  assert_line --index 1 "test2"
}

@test "runs multiple commands without args" {
  run bee batch "echo" "echo test1" "echo" "bee::log_var BEE_RESOLVE_PLUGIN_PATH"
  assert_line --index 0 "test1"
  assert_line --index 1 "${BEE_RESOLVE_PLUGIN_PATH}"
}

################################################################################
# plugins
################################################################################

@test "resolves latest plugin" {
  run bee batch "bee::resolve_plugin testplugin" "bee::log_var BEE_RESOLVE_PLUGIN_PATH"
  assert_output "${_bee_plugins_path}/testplugin/2.0.0/testplugin.sh"
}

@test "resolves plugin with exact version" {
  run bee batch "bee::resolve_plugin testplugin:1.0.0" "bee::log_var BEE_RESOLVE_PLUGIN_PATH"
  assert_output "${_bee_plugins_path}/testplugin/1.0.0/testplugin.sh"
}

@test "won't resolve plugin that doesn't exit" {
  run bee batch "bee::resolve_plugin missing" "bee::log_var BEE_RESOLVE_PLUGIN_PATH"
  refute_output
}

@test "won't resolve plugin with exact version that doesn't exit" {
  run bee batch "bee::resolve_plugin missing:1.0.0" "bee::log_var BEE_RESOLVE_PLUGIN_PATH"
  refute_output
}

@test "runs plugin" {
  run bee testplugin
  assert_output "hello from testplugin 2.0.0"
}

@test "runs plugin with args" {
  run bee testplugin test
  assert_output "hello from testplugin 2.0.0 - test"
}

@test "runs multiple plugin commands" {
  run bee batch "testplugin:1.0.0 test1" "testplugin:2.0.0 test2"
  assert_line --index 0 "hello from testplugin 1.0.0 - test1"
  assert_line --index 1 "hello from testplugin 2.0.0 - test2"
}
