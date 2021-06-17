setup() {
  load 'test-helper.bash'
  _source_bee
  bee::load_beerc
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
  run bee::run
  assert_output "bee help"
}

@test "runs args" {
  run bee::run echo "test"
  assert_output "test"
}

@test "runs internal bee command" {
  run bee::run bee::log_echo "test"
  assert_output "test"
}

@test "runs bee module" {
  run bee::run testmodule
  assert_line --index 0 "# testmodule sourced"
  assert_line --index 1 "hello from testmodule"
}

@test "runs bee module with args" {
  run bee::run testmodule "test"
  assert_line --index 0 "# testmodule sourced"
  assert_line --index 1 "hello from testmodule - test"
}

@test "runs bee plugin" {
  run bee::run testplugin
  assert_line --index 0 "# testplugin 2.0.0 sourced"
  assert_line --index 1 "testplugin 2.0.0 help"
}

@test "runs bee plugin with args" {
  run bee::run testplugin greet "test"
  assert_line --index 0 "# testplugin 2.0.0 sourced"
  assert_line --index 1 "greeting test from testplugin 2.0.0"
}

@test "runs bee plugin with exact version" {
  run bee::run testplugin:1.0.0
  assert_line --index 0 "# testplugin 1.0.0 sourced"
  assert_line --index 1 "testplugin 1.0.0 help"
}

@test "runs bee plugin with exact version with args" {
  run bee::run testplugin:1.0.0 greet "test"
  assert_line --index 0 "# testplugin 1.0.0 sourced"
  assert_line --index 1 "greeting test from testplugin 1.0.0"
}

#################################################################################
## options
#################################################################################

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

################################################################################
# modules
################################################################################

@test "loads module" {
  run bee::load_module testmodule
  assert_output "# testmodule sourced"

  bee::load_module testmodule
  run bee::log_var BEE_LOAD_MODULE_NAME
  assert_output "testmodule"
}

@test "loads another module" {
  bee::load_module testmodule
  run bee::load_module othertestmodule
  assert_output "# othertestmodule sourced"

  bee::load_module othertestmodule
  run bee::log_var BEE_LOAD_MODULE_NAME
  assert_output "othertestmodule"
}

@test "doesn't load unknown module" {
  run bee::load_module unknown
  assert_success
  refute_output

  bee::load_module unknown
  run bee::log_var BEE_LOAD_MODULE_NAME
  refute_output
}

@test "loads module only once" {
  bee::load_module testmodule
  run bee::load_module testmodule
  assert_success
  refute_output
}

@test "loads unknown module only once" {
  bee::load_module unknown
  run bee::load_module unknown
  assert_success
  refute_output
}

@test "caches module" {
  bee::load_module testmodule
  bee::load_module othertestmodule
  run bee::load_module testmodule
  refute_output

  bee::load_module testmodule
  run bee::log_var BEE_LOAD_MODULE_NAME
  assert_output "testmodule"
}

@test "caches unknown module" {
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
  bee::load_module testmodule
  run bee::run_module testmodule
  assert_output "hello from testmodule"
}

@test "runs module with args" {
  bee::load_module testmodule
  run bee::run_module testmodule "test"
  assert_output "hello from testmodule - test"
}

################################################################################
# plugins
################################################################################

@test "resolves latest plugin" {
  bee::resolve_plugin testplugin
  run bee::log_var BEE_RESOLVE_PLUGIN_NAME
  assert_output "testplugin"

  run bee::log_var BEE_RESOLVE_PLUGIN_VERSION
  assert_output "2.0.0"

  run bee::log_var BEE_RESOLVE_PLUGIN_PATH
  assert_output "${BEE_PLUGINS_PATH}/testplugin/2.0.0/testplugin.sh"
}

@test "resolves plugin with exact version" {
  bee::resolve_plugin testplugin:1.0.0
  run bee::log_var BEE_RESOLVE_PLUGIN_NAME
  assert_output "testplugin"

  run bee::log_var BEE_RESOLVE_PLUGIN_VERSION
  assert_output "1.0.0"

  run bee::log_var BEE_RESOLVE_PLUGIN_PATH
  assert_output "${BEE_PLUGINS_PATH}/testplugin/1.0.0/testplugin.sh"
}

@test "doesn't resolve plugin with unknown version" {
  bee::resolve_plugin testplugin:9.0.0
  run bee::log_var BEE_RESOLVE_PLUGIN_NAME
  refute_output

  run bee::log_var BEE_RESOLVE_PLUGIN_VERSION
  refute_output

  run bee::log_var BEE_RESOLVE_PLUGIN_PATH
  refute_output
}

@test "resolves another plugin" {
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
  bee::resolve_plugin unknown
  run bee::log_var BEE_RESOLVE_PLUGIN_NAME
  refute_output

  run bee::log_var BEE_RESOLVE_PLUGIN_VERSION
  refute_output

  run bee::log_var BEE_RESOLVE_PLUGIN_PATH
  refute_output
}

@test "doesn't resolve unknown plugin with exact version" {
  bee::resolve_plugin unknown:1.0.0
  run bee::log_var BEE_RESOLVE_PLUGIN_NAME
  refute_output

  run bee::log_var BEE_RESOLVE_PLUGIN_VERSION
  refute_output

  run bee::log_var BEE_RESOLVE_PLUGIN_PATH
  refute_output
}

@test "caches resolved plugin paths" {
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
  run bee::load_plugin testplugin:1.0.0
  assert_output "# testplugin 1.0.0 sourced"

  bee::load_plugin testplugin:1.0.0
  run bee::log_var BEE_LOAD_PLUGIN_NAME
  assert_output "testplugin"
}

@test "loads plugin only once" {
  bee::load_plugin testplugin:1.0.0
  run bee::load_plugin testplugin:1.0.0
  refute_output
}

@test "loads another plugin" {
  bee::load_plugin testplugin:1.0.0
  run bee::load_plugin othertestplugin:1.0.0
  assert_output "# othertestplugin 1.0.0 sourced"

  bee::load_plugin othertestplugin:1.0.0
  run bee::log_var BEE_LOAD_PLUGIN_NAME
  assert_output "othertestplugin"
}

@test "doesn't load unknown plugin" {
  run bee::load_plugin unkown
  assert_success
  refute_output
}

@test "unknown plugin resets plugin name" {
  bee::load_plugin testplugin:1.0.0
  bee::load_plugin unkown
  run bee::log_var BEE_LOAD_PLUGIN_NAME
  refute_output
}

@test "loads plugin dependencies" {
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
  bee::load_plugin testplugin
  run bee::run_plugin testplugin
  assert_output "testplugin 2.0.0 help"
}

@test "runs plugin with args" {
  bee::load_plugin testplugin
  run bee::run_plugin testplugin greet "test"
  assert_output "greeting test from testplugin 2.0.0"
}
