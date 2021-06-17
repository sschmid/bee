setup() {
  load 'test-helper.bash'
  _source_bee
  bee::load_beerc
}

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
# dependencies
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
