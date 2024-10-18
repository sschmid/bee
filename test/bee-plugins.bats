setup() {
  load 'test-helper.bash'
  _set_beerc
  _source_beerc
}

assert_plugin() {
  local plugin="$1" expected_name="$2" expected_version="$3"
  run bee --batch "bee::resolve_plugin ${plugin}" \
    "env BEE_RESOLVE_PLUGIN_NAME BEE_RESOLVE_PLUGIN_VERSION BEE_RESOLVE_PLUGIN_BASE_PATH BEE_RESOLVE_PLUGIN_FULL_PATH BEE_RESOLVE_PLUGIN_JSON_PATH"
  assert_success
  cat << EOF | assert_output -
${expected_name}
${expected_version}
${BEE_PLUGINS_PATHS}/${expected_name}
${BEE_PLUGINS_PATHS}/${expected_name}/${expected_version}/${expected_name}.bash
${BEE_PLUGINS_PATHS}/${expected_name}/${expected_version}/plugin.json
EOF
}

assert_local_plugin() {
  local plugin="$1" expected_name="$2"
  run bee --batch "bee::resolve_plugin ${plugin}" \
    "env BEE_RESOLVE_PLUGIN_NAME BEE_RESOLVE_PLUGIN_VERSION BEE_RESOLVE_PLUGIN_BASE_PATH BEE_RESOLVE_PLUGIN_FULL_PATH BEE_RESOLVE_PLUGIN_JSON_PATH"
  assert_success
  cat << EOF | assert_output -
${expected_name}
local
${BATS_TEST_DIRNAME}/fixtures/custom_plugins/${expected_name}
${BATS_TEST_DIRNAME}/fixtures/custom_plugins/${expected_name}/${expected_name}.bash
${BATS_TEST_DIRNAME}/fixtures/custom_plugins/${expected_name}/plugin.json
EOF
}

assert_no_plugin() {
  local plugin="$1"
  run bee --batch "bee::resolve_plugin ${plugin}" \
    "env BEE_RESOLVE_PLUGIN_NAME BEE_RESOLVE_PLUGIN_VERSION BEE_RESOLVE_PLUGIN_BASE_PATH BEE_RESOLVE_PLUGIN_FULL_PATH BEE_RESOLVE_PLUGIN_JSON_PATH"
  assert_success
  refute_output
}

assert_last_plugin() {
  local first_plugin="$1" last_plugin="$2" expected_name="$3" expected_version="$4"
  run bee --batch \
    "bee::resolve_plugin ${first_plugin}" \
    "bee::resolve_plugin ${last_plugin}" \
    "env BEE_RESOLVE_PLUGIN_NAME BEE_RESOLVE_PLUGIN_VERSION BEE_RESOLVE_PLUGIN_BASE_PATH BEE_RESOLVE_PLUGIN_FULL_PATH BEE_RESOLVE_PLUGIN_JSON_PATH"
  cat << EOF | assert_output -
${expected_name}
${expected_version}
${BEE_PLUGINS_PATHS}/${expected_name}
${BEE_PLUGINS_PATHS}/${expected_name}/${expected_version}/${expected_name}.bash
${BEE_PLUGINS_PATHS}/${expected_name}/${expected_version}/plugin.json
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

@test "resolves local plugin without local tag" {
  # shellcheck disable=SC2030,SC2031
  export TEST_BEE_PLUGINS_PATHS_CUSTOM=1
  assert_local_plugin localplugin localplugin
}

@test "resolves local plugin with local tag" {
  # shellcheck disable=SC2030,SC2031
  export TEST_BEE_PLUGINS_PATHS_CUSTOM=1
  assert_local_plugin localplugin:local localplugin
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
    "env BEE_LOAD_PLUGIN_NAME BEE_LOAD_PLUGIN_PATH BEE_LOAD_PLUGIN_JSON_PATH"
  assert_success
  cat << EOF | assert_output -
# testplugin 1.0.0 sourced
testplugin
${BATS_TEST_DIRNAME}/fixtures/plugins/testplugin/1.0.0/testplugin.bash
${BATS_TEST_DIRNAME}/fixtures/plugins/testplugin/1.0.0/plugin.json
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
    "env BEE_LOAD_PLUGIN_NAME BEE_LOAD_PLUGIN_PATH BEE_LOAD_PLUGIN_JSON_PATH"
  assert_success
  cat << EOF | assert_output -
# testplugin 1.0.0 sourced
# othertestplugin 1.0.0 sourced
othertestplugin
${BATS_TEST_DIRNAME}/fixtures/plugins/othertestplugin/1.0.0/othertestplugin.bash
${BATS_TEST_DIRNAME}/fixtures/plugins/othertestplugin/1.0.0/plugin.json
EOF
}

@test "doesn't load unknown plugin" {
  run bee --batch \
    "bee::load_plugin unknown" \
    "env BEE_LOAD_PLUGIN_NAME BEE_LOAD_PLUGIN_PATH BEE_LOAD_PLUGIN_JSON_PATH"
  assert_success
  refute_output
}

@test "unknown plugin resets plugin name" {
  run bee --batch \
    "bee::load_plugin testplugin:1.0.0" \
    "bee::load_plugin unknown" \
    "env BEE_LOAD_PLUGIN_NAME BEE_LOAD_PLUGIN_PATH BEE_LOAD_PLUGIN_JSON_PATH"
  assert_success
  assert_output "# testplugin 1.0.0 sourced"
}

@test "loads plugin dependencies" {
  run bee --batch \
    "bee::load_plugin testplugindepsdep" \
    "env BEE_LOAD_PLUGIN_NAME BEE_LOAD_PLUGIN_PATH BEE_LOAD_PLUGIN_JSON_PATH"
  assert_success
  cat << EOF | assert_output -
# testplugindepsdep 1.0.0 sourced
# testplugindeps 1.0.0 sourced
# testplugin 1.0.0 sourced
# othertestplugin 1.0.0 sourced
testplugindepsdep
${BATS_TEST_DIRNAME}/fixtures/plugins/testplugindepsdep/1.0.0/testplugindepsdep.bash
${BATS_TEST_DIRNAME}/fixtures/plugins/testplugindepsdep/1.0.0/plugin.json
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
${BEE_ERROR} Missing plugin: 'missing:1.0.0'
${BEE_ERROR} Missing plugin: 'othermissing:1.0.0'
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

@test "fails when plugin help is missing" {
  run -127 bee --batch \
    "bee::load_plugin testplugindeps" \
    "bee::run_plugin testplugindeps"
  assert_failure
  assert_output --partial "testplugindeps::help: command not found"
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

@test "sources optional os file" {
  run bee --batch \
    "bee::load_plugin testplugin:1.5.0" \
    "bee::run_plugin testplugin os test"
  assert_success
  assert_output "os: test"
}

################################################################################
# multiple plugin folders
################################################################################

@test "loads plugin and dependencies from custom folder" {
  # shellcheck disable=SC2030,SC2031
  export TEST_BEE_PLUGINS_PATHS_CUSTOM=1
  run bee bee::load_plugin customtestplugin
  assert_success
  cat << 'EOF' | assert_output -
# customtestplugin 1.0.0 sourced
# testplugin 1.0.0 sourced
EOF
}

@test "loads local plugin and dependencies from custom folder" {
  # shellcheck disable=SC2030,SC2031
  export TEST_BEE_PLUGINS_PATHS_CUSTOM=1
  run bee bee::load_plugin localplugin
  assert_success
  cat << 'EOF' | assert_output -
# localplugin sourced
# testplugin 1.0.0 sourced
# othertestplugin 1.0.0 sourced
EOF
}

@test "completes plugins with comp function" {
  assert_comp "bee testplugin " "testplugincomp"
}

@test "completes plugins without comp function" {
  local expected=(greet help)
  assert_comp "bee othertestplugin " "${expected[*]}"
}

@test "only completes first arg for plugins without comp function" {
  assert_comp "bee othertestplugin help "
}

@test "completes mapped plugin version" {
  _setup_beefile 'BEE_PLUGINS=(testplugin:1.0.0)'
  local expected=(greet help)
  assert_comp "bee testplugin " "${expected[*]}"
}
