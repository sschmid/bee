setup() {
  load 'test-helper.bash'
}

teardown() {
  _teardown_test_tmp_dir
}

@test "is executable" {
  assert_file_executable "${PROJECT_ROOT}/src/bee"
}

################################################################################
# run
################################################################################

@test "prints bee help when no args" {
  run bee
  assert_output "bee help"
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

################################################################################
# beerc
################################################################################

@test "loads beerc when specified" {
  _set_test_beerc
  run bee echo
  assert_output "# test beerc sourced"
}

@test "loads beerc only once" {
  _set_test_beerc
  _source_bee
  bee::load_beerc
  run bee::load_beerc
  refute_output
}

@test "creates default .beerc" {
  _setup_test_tmp_dir
  BEE_RC="${TMP_TEST_DIR}/tmp-beerc.sh"
  run bee echo "test"
  assert_file_exist "${BEE_RC}"
}

#################################################################################
## options
#################################################################################

@test "enable quiet mode" {
  run bee -q bee::log "test"
  refute_output

  run bee --quiet bee::log "test"
  refute_output
}

@test "batches multiple commands with args" {
  run bee -b "echo test1 test2" "echo test3 test4"
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

################################################################################
# modules
################################################################################

@test "loads module" {
  _source_bee
  run bee::load_module testmodule
  assert_output "# testmodule sourced"

  bee::load_module testmodule
  run bee::log_var BEE_LOAD_MODULE_NAME
  assert_output "testmodule"
}

@test "loads another module" {
  _source_bee
  bee::load_module testmodule
  run bee::load_module othertestmodule
  assert_output "# othertestmodule sourced"

  bee::load_module othertestmodule
  run bee::log_var BEE_LOAD_MODULE_NAME
  assert_output "othertestmodule"
}

@test "doesn't load unknown module" {
  _source_bee
  run bee::load_module unknown
  assert_success
  refute_output

  bee::load_module unknown
  run bee::log_var BEE_LOAD_MODULE_NAME
  refute_output
}

@test "loads module only once" {
  _source_bee
  bee::load_module testmodule
  run bee::load_module testmodule
  assert_success
  refute_output
}

@test "loads unknown module only once" {
  _source_bee
  bee::load_module unknown
  run bee::load_module unknown
  assert_success
  refute_output
}

@test "caches module" {
  _source_bee
  bee::load_module testmodule
  bee::load_module othertestmodule
  run bee::load_module testmodule
  refute_output

  bee::load_module testmodule
  run bee::log_var BEE_LOAD_MODULE_NAME
  assert_output "testmodule"
}

@test "caches unknown module" {
  _source_bee
  bee::load_module testmodule
  bee::load_module unknown
  bee::load_module testmodule
  run bee::load_module unknown
  assert_success
  refute_output

  bee::load_module unknown
  run bee::log_var BEE_LOAD_MODULE_NAME
  refute_output
}

@test "runs module" {
  _source_bee
  bee::load_module testmodule
  run bee::run_module testmodule
  assert_output "hello from testmodule"
}

@test "runs module with args" {
  _source_bee
  bee::load_module testmodule
  run bee::run_module testmodule "test"
  assert_output "hello from testmodule - test"
}

################################################################################
# plugins
################################################################################

@test "resolves latest plugin" {
  _source_bee
  bee::resolve_plugin testplugin
  run bee::log_var BEE_RESOLVE_PLUGIN_NAME
  assert_output "testplugin"

  run bee::log_var BEE_RESOLVE_PLUGIN_VERSION
  assert_output "2.0.0"

  run bee::log_var BEE_RESOLVE_PLUGIN_PATH
  assert_output "${BEE_PLUGINS_PATH}/testplugin/2.0.0/testplugin.sh"
}

@test "resolves plugin with exact version" {
  _source_bee
  bee::resolve_plugin testplugin:1.0.0
  run bee::log_var BEE_RESOLVE_PLUGIN_NAME
  assert_output "testplugin"

  run bee::log_var BEE_RESOLVE_PLUGIN_VERSION
  assert_output "1.0.0"

  run bee::log_var BEE_RESOLVE_PLUGIN_PATH
  assert_output "${BEE_PLUGINS_PATH}/testplugin/1.0.0/testplugin.sh"
}

@test "doesn't resolve plugin with unknown version" {
  _source_bee
  bee::resolve_plugin testplugin:9.0.0
  run bee::log_var BEE_RESOLVE_PLUGIN_NAME
  refute_output

  run bee::log_var BEE_RESOLVE_PLUGIN_VERSION
  refute_output

  run bee::log_var BEE_RESOLVE_PLUGIN_PATH
  refute_output
}

@test "resolves another plugin" {
  _source_bee
  bee::resolve_plugin testplugin:2.0.0
  bee::resolve_plugin othertestplugin
  run bee::log_var BEE_RESOLVE_PLUGIN_NAME
  assert_output "othertestplugin"

  run bee::log_var BEE_RESOLVE_PLUGIN_VERSION
  assert_output "1.0.0"

  run bee::log_var BEE_RESOLVE_PLUGIN_PATH
  assert_output "${BEE_PLUGINS_PATH}/othertestplugin/1.0.0/othertestplugin.sh"
}

@test "doesn't resolve unknown plugin" {
  _source_bee
  bee::resolve_plugin unknown
  run bee::log_var BEE_RESOLVE_PLUGIN_NAME
  refute_output

  run bee::log_var BEE_RESOLVE_PLUGIN_VERSION
  refute_output

  run bee::log_var BEE_RESOLVE_PLUGIN_PATH
  refute_output
}

@test "doesn't resolve unknown plugin with exact version" {
  _source_bee
  bee::resolve_plugin unknown:1.0.0
  run bee::log_var BEE_RESOLVE_PLUGIN_NAME
  refute_output

  run bee::log_var BEE_RESOLVE_PLUGIN_VERSION
  refute_output

  run bee::log_var BEE_RESOLVE_PLUGIN_PATH
  refute_output
}

@test "caches resolved plugin paths" {
  _source_bee
  bee::resolve_plugin testplugin:1.0.0
  bee::resolve_plugin testplugin
  bee::resolve_plugin testplugin:2.0.0
  bee::resolve_plugin missing
  bee::resolve_plugin missing:1.0.0
  bee::resolve_plugin echo
  bee::resolve_plugin echo
  bee::resolve_plugin missing
  bee::resolve_plugin missing:1.0.0
}

################################################################################
# plugins dependencies
################################################################################

@test "loads plugin" {
  _source_bee
  run bee::load_plugin testplugin:1.0.0
  assert_output "# testplugin 1.0.0 sourced"

  bee::load_plugin testplugin:1.0.0
  run bee::log_var BEE_LOAD_PLUGIN_NAME
  assert_output "testplugin"
}

@test "loads plugin only once" {
  _source_bee
  bee::load_plugin testplugin:1.0.0
  run bee::load_plugin testplugin:1.0.0
  refute_output
}

@test "loads another plugin" {
  _source_bee
  bee::load_plugin testplugin:1.0.0
  run bee::load_plugin othertestplugin:1.0.0
  assert_output "# othertestplugin 1.0.0 sourced"

  bee::load_plugin othertestplugin:1.0.0
  run bee::log_var BEE_LOAD_PLUGIN_NAME
  assert_output "othertestplugin"
}

@test "doesn't load unknown plugin" {
  _source_bee
  run bee::load_plugin unkown
  assert_success
  refute_output
}

@test "unknown plugin resets plugin name" {
  _source_bee
  bee::load_plugin testplugin:1.0.0
  bee::load_plugin unkown
  run bee::log_var BEE_LOAD_PLUGIN_NAME
  refute_output
}

@test "loads plugin dependencies" {
  _source_bee
  run bee::load_plugin testplugindepsdep
  assert_line --index 0 "# testplugindepsdep 1.0.0 sourced"
  assert_line --index 1 "# testplugindeps 1.0.0 sourced"
  assert_line --index 2 "# testplugin 1.0.0 sourced"
  assert_line --index 3 "# othertestplugin 1.0.0 sourced"

  bee::load_plugin testplugindepsdep
  run bee::log_var BEE_LOAD_PLUGIN_NAME
  assert_output testplugindepsdep
}

@test "fails on missing plugin dependency" {
  _source_bee
  run bee::load_plugin testpluginmissingdep
  assert_failure
  assert_line --index 0 "# testpluginmissingdep 1.0.0 sourced"
  assert_line --index 1 "# testplugindepsdep 1.0.0 sourced"
  assert_line --index 2 "# testplugindeps 1.0.0 sourced"
  assert_line --index 3 "# testplugin 1.0.0 sourced"
  assert_line --index 4 "# othertestplugin 1.0.0 sourced"
  assert_line --index 5 "🔴 Missing plugin: 'missing:1.0.0'"
  assert_line --index 6 "🔴 Missing plugin: 'othermissing:1.0.0'"
}

@test "runs plugin" {
  _source_bee
  bee::load_plugin testplugin
  run bee::run_plugin testplugin
  assert_output "testplugin 2.0.0 help"
}

@test "runs plugin with args" {
  _source_bee
  bee::load_plugin testplugin
  run bee::run_plugin testplugin greet "test"
  assert_output "greeting test from testplugin 2.0.0"
}
