setup() {
  load 'test-helper.bash'
  _set_beerc
  _source_beerc
}

assert_plugin() {
  local plugin="$1" expected_name="$2" expected_version="$3"
  run bee --batch "bee::resolve_plugin ${plugin}" \
    "env BEE_RESOLVE_PLUGIN_NAME BEE_RESOLVE_PLUGIN_VERSION BEE_RESOLVE_PLUGIN_PATH"
  assert_success
  cat << EOF | assert_output -
${expected_name}
${expected_version}
${BEE_PLUGINS_PATHS}/${expected_name}/${expected_version}/${expected_name}.bash
EOF
}

assert_no_plugin() {
  local plugin="$1"
  run bee --batch "bee::resolve_plugin ${plugin}" \
    "env BEE_RESOLVE_PLUGIN_NAME BEE_RESOLVE_PLUGIN_VERSION BEE_RESOLVE_PLUGIN_PATH"
  assert_success
  refute_output
}

assert_last_plugin() {
  local first_plugin="$1" last_plugin="$2" expected_name="$3" expected_version="$4"
  run bee --batch \
    "bee::resolve_plugin ${first_plugin}" \
    "bee::resolve_plugin ${last_plugin}" \
    "env BEE_RESOLVE_PLUGIN_NAME BEE_RESOLVE_PLUGIN_VERSION BEE_RESOLVE_PLUGIN_PATH"
  cat << EOF | assert_output -
${expected_name}
${expected_version}
${BEE_PLUGINS_PATHS}/${expected_name}/${expected_version}/${expected_name}.bash
EOF
}

@test "resolves latest plugin version" {
  assert_plugin testplugin testplugin 2.0.0
}

@test "resolves plugin with exact version" {
  assert_plugin testplugin:1.0.0 testplugin 1.0.0
}

@test "doesn't resolve plugin with unknown version" {
  assert_no_plugin testplugin:9.0.0
}

@test "resolves another plugin" {
  assert_last_plugin testplugin:2.0.0 othertestplugin othertestplugin 1.0.0
}

@test "doesn't resolve unknown plugin" {
  assert_no_plugin unknown
}

@test "doesn't resolve unknown plugin with exact version" {
  assert_no_plugin unknown:1.0.0
}

# this is a manual test / sanity check
#@test "caches resolved plugin paths" {
#  run bee --batch \
#    "bee::resolve_plugin testplugin:1.0.0" \
#    "bee::resolve_plugin testplugin" \
#    "bee::resolve_plugin testplugin:2.0.0" \
#    "bee::resolve_plugin missing" \
#    "bee::resolve_plugin missing:1.0.0" \
#    "bee::resolve_plugin echo" \
#    "bee::resolve_plugin echo" \
#    "bee::resolve_plugin missing" \
#    "bee::resolve_plugin missing:1.0.0"
#  assert_failure # "fail on purpose to print steps"
#}

################################################################################
# dependencies
################################################################################

@test "loads plugin" {
  run bee --batch \
    "bee::load_plugin testplugin:1.0.0" \
    "env BEE_LOAD_PLUGIN_NAME"
  assert_success
  cat << EOF | assert_output -
# testplugin 1.0.0 sourced
testplugin
EOF
}

@test "loads plugin only once" {
  run bee --batch \
    "bee::load_plugin testplugin:1.0.0" \
    "bee::load_plugin testplugin:1.0.0" \
    "env BEE_LOAD_PLUGIN_NAME"
  assert_success
  cat << EOF | assert_output -
# testplugin 1.0.0 sourced
testplugin
EOF
}

@test "loads another plugin" {
  run bee --batch \
    "bee::load_plugin testplugin:1.0.0" \
    "bee::load_plugin othertestplugin:1.0.0" \
    "env BEE_LOAD_PLUGIN_NAME"
  assert_success
  cat << EOF | assert_output -
# testplugin 1.0.0 sourced
# othertestplugin 1.0.0 sourced
othertestplugin
EOF
}

@test "doesn't load unknown plugin" {
  run bee --batch \
    "bee::load_plugin unknown" \
    "env BEE_LOAD_PLUGIN_NAME"
  assert_success
  refute_output
}

@test "unknown plugin resets plugin name" {
  run bee --batch \
    "bee::load_plugin testplugin:1.0.0" \
    "bee::load_plugin unknown" \
    "env BEE_LOAD_PLUGIN_NAME"
  assert_success
  assert_output "# testplugin 1.0.0 sourced"
}

@test "loads plugin dependencies" {
  run bee --batch \
    "bee::load_plugin testplugindepsdep" \
    "env BEE_LOAD_PLUGIN_NAME"
  assert_success
  cat << EOF | assert_output -
# testplugindepsdep 1.0.0 sourced
# testplugindeps 1.0.0 sourced
# testplugin 1.0.0 sourced
# othertestplugin 1.0.0 sourced
testplugindepsdep
EOF
}

@test "fails on missing plugin dependency" {
  run bee --batch \
    "bee::load_plugin testpluginmissingdep" \
    "env BEE_LOAD_PLUGIN_NAME"
  assert_failure
  cat << EOF | assert_output -
# testpluginmissingdep 1.0.0 sourced
# testplugindepsdep 1.0.0 sourced
# testplugindeps 1.0.0 sourced
# testplugin 1.0.0 sourced
# othertestplugin 1.0.0 sourced
${BEE_ERR} Missing plugin: 'missing:1.0.0'
${BEE_ERR} Missing plugin: 'othermissing:1.0.0'
EOF
}

@test "runs plugin help when no args" {
  run bee --batch \
    "bee::load_plugin testplugin" \
    "bee::run_plugin testplugin"
  assert_success
  cat << 'EOF' | assert_output -
# testplugin 2.0.0 sourced
testplugin 2.0.0 help
EOF
}

@test "runs plugin with args" {
  run bee --batch \
    "bee::load_plugin testplugin" \
    "bee::run_plugin testplugin greet test"
  assert_success
  cat << 'EOF' | assert_output -
# testplugin 2.0.0 sourced
greeting test from testplugin 2.0.0
EOF
}

################################################################################
# multiple plugin folders
################################################################################

@test "loads plugin and dependencies from custom folder" {
  export TEST_BEE_PLUGINS_PATHS_CUSTOM=1
  run bee bee::load_plugin "customtestplugin"
  assert_success
  cat << 'EOF' | assert_output -
# customtestplugin 1.0.0 sourced
# testplugin 1.0.0 sourced
EOF
}
