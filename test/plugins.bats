setup() {
  load 'test-helper.bash'
  _set_test_beerc
  _source_bee
}

@test "resolves latest plugin" {
  bee::resolve_plugin testplugin
  assert_equal "${BEE_RESOLVE_PLUGIN_NAME}" "testplugin"
  assert_equal "${BEE_RESOLVE_PLUGIN_VERSION}" "2.0.0"
  assert_equal "${BEE_RESOLVE_PLUGIN_PATH}" "${BEE_PLUGINS_PATHS}/testplugin/2.0.0/testplugin.bash"
}

@test "resolves plugin with exact version" {
  bee::resolve_plugin testplugin:1.0.0
  assert_equal "${BEE_RESOLVE_PLUGIN_NAME}" "testplugin"
  assert_equal "${BEE_RESOLVE_PLUGIN_VERSION}" "1.0.0"
  assert_equal "${BEE_RESOLVE_PLUGIN_PATH}" "${BEE_PLUGINS_PATHS}/testplugin/1.0.0/testplugin.bash"
}

@test "doesn't resolve plugin with unknown version" {
  bee::resolve_plugin testplugin:9.0.0
  assert_equal "${BEE_RESOLVE_PLUGIN_NAME}" ""
  assert_equal "${BEE_RESOLVE_PLUGIN_VERSION}" ""
  assert_equal "${BEE_RESOLVE_PLUGIN_PATH}" ""
}

@test "resolves another plugin" {
  bee::resolve_plugin testplugin:2.0.0
  bee::resolve_plugin othertestplugin
  assert_equal "${BEE_RESOLVE_PLUGIN_NAME}" "othertestplugin"
  assert_equal "${BEE_RESOLVE_PLUGIN_VERSION}" "1.0.0"
  assert_equal "${BEE_RESOLVE_PLUGIN_PATH}" "${BEE_PLUGINS_PATHS}/othertestplugin/1.0.0/othertestplugin.bash"
}

@test "doesn't resolve unknown plugin" {
  bee::resolve_plugin unknown
  assert_equal "${BEE_RESOLVE_PLUGIN_NAME}" ""
  assert_equal "${BEE_RESOLVE_PLUGIN_VERSION}" ""
  assert_equal "${BEE_RESOLVE_PLUGIN_PATH}" ""
}

@test "doesn't resolve unknown plugin with exact version" {
  bee::resolve_plugin unknown:1.0.0
  assert_equal "${BEE_RESOLVE_PLUGIN_NAME}" ""
  assert_equal "${BEE_RESOLVE_PLUGIN_VERSION}" ""
  assert_equal "${BEE_RESOLVE_PLUGIN_PATH}" ""
}

# this is a manual test / sanity check
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
  # assert_output "fail on purpose to print steps"
}

################################################################################
# dependencies
################################################################################

@test "loads plugin" {
  run _strict bee::load_plugin testplugin:1.0.0
  assert_output "# testplugin 1.0.0 sourced"

  bee::load_plugin testplugin:1.0.0
  assert_equal "${BEE_LOAD_PLUGIN_NAME}" "testplugin"
}

@test "loads plugin only once" {
  bee::load_plugin testplugin:1.0.0
  run _strict bee::load_plugin testplugin:1.0.0
  refute_output
}

@test "loads another plugin" {
  bee::load_plugin testplugin:1.0.0
  run _strict bee::load_plugin othertestplugin:1.0.0
  assert_output "# othertestplugin 1.0.0 sourced"

  bee::load_plugin othertestplugin:1.0.0
  assert_equal "${BEE_LOAD_PLUGIN_NAME}" "othertestplugin"
}

@test "doesn't load unknown plugin" {
  run _strict bee::load_plugin unkown
  assert_success
  refute_output
  assert_equal "${BEE_LOAD_PLUGIN_NAME}" ""
}

@test "unknown plugin resets plugin name" {
  bee::load_plugin testplugin:1.0.0
  bee::load_plugin unkown
  assert_equal "${BEE_LOAD_PLUGIN_NAME}" ""
}

@test "loads plugin dependencies" {
  run _strict bee::load_plugin testplugindepsdep
  assert_line --index 0 "# testplugindepsdep 1.0.0 sourced"
  assert_line --index 1 "# testplugindeps 1.0.0 sourced"
  assert_line --index 2 "# testplugin 1.0.0 sourced"
  assert_line --index 3 "# othertestplugin 1.0.0 sourced"

  bee::load_plugin testplugindepsdep
  assert_equal "${BEE_LOAD_PLUGIN_NAME}" "testplugindepsdep"
}

@test "fails on missing plugin dependency" {
  run _strict bee::load_plugin testpluginmissingdep
  assert_failure
  assert_line --index 0 "# testpluginmissingdep 1.0.0 sourced"
  assert_line --index 1 "# testplugindepsdep 1.0.0 sourced"
  assert_line --index 2 "# testplugindeps 1.0.0 sourced"
  assert_line --index 3 "# testplugin 1.0.0 sourced"
  assert_line --index 4 "# othertestplugin 1.0.0 sourced"
  assert_line --index 5 "🔴 Missing plugin: 'missing:1.0.0'"
  assert_line --index 6 "🔴 Missing plugin: 'othermissing:1.0.0'"
}

@test "runs plugin help when no args" {
  bee::load_plugin testplugin
  run _strict bee::run_plugin testplugin
  assert_output "testplugin 2.0.0 help"
}

@test "runs plugin with args" {
  bee::load_plugin testplugin
  run _strict bee::run_plugin testplugin greet "test"
  assert_output "greeting test from testplugin 2.0.0"
}

################################################################################
# multiple plugin folders
################################################################################

@test "loads plugin and dependencies from custom folder" {
  BEE_PLUGINS_PATHS=(
    "${PROJECT_ROOT}/test/fixtures/plugins"
    "${PROJECT_ROOT}/test/fixtures/custom_plugins"
  )
  run _strict bee::load_plugin customtestplugin
  assert_line --index 0 "# customtestplugin 1.0.0 sourced"
  assert_line --index 1 "# testplugin 1.0.0 sourced"
}
