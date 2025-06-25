setup() {
  load 'test-helper'
  _common_setup
  _export_beerc
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
  assert_plugin plugin_1 plugin_1 2.0.0
}

@test "resolves plugin with exact version" {
  assert_plugin plugin_1:1.0.0 plugin_1 1.0.0
}

@test "doesn't resolve plugin with unknown version" {
  assert_no_plugin plugin_1:9.0.0
}

@test "resolves another plugin" {
  assert_last_plugin plugin_1:2.0.0 plugin_2 plugin_2 1.0.0
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
  assert_local_plugin local_plugin local_plugin
}

@test "resolves local plugin with local tag" {
  # shellcheck disable=SC2030,SC2031
  export TEST_BEE_PLUGINS_PATHS_CUSTOM=1
  assert_local_plugin local_plugin:local local_plugin
}

# this is a manual test / sanity check
#@test "caches resolved plugin paths" {
#  run bee --batch \
#    "bee::resolve_plugin plugin_1:1.0.0" \
#    "bee::resolve_plugin plugin_1" \
#    "bee::resolve_plugin plugin_1:2.0.0" \
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
    "bee::load_plugin plugin_1:1.0.0" \
    "env BEE_LOAD_PLUGIN_NAME BEE_LOAD_PLUGIN_PATH BEE_LOAD_PLUGIN_JSON_PATH"
  assert_success
  cat << EOF | assert_output -
# plugin_1 1.0.0 sourced
plugin_1
${BATS_TEST_DIRNAME}/fixtures/plugins/plugin_1/1.0.0/plugin_1.bash
${BATS_TEST_DIRNAME}/fixtures/plugins/plugin_1/1.0.0/plugin.json
EOF
}

@test "loads plugin only once" {
  run bee --batch \
    "bee::load_plugin plugin_1:1.0.0" \
    "bee::load_plugin plugin_1:1.0.0" \
    "env BEE_LOAD_PLUGIN_NAME"
  assert_success
  cat << EOF | assert_output -
# plugin_1 1.0.0 sourced
plugin_1
EOF
}

@test "loads another plugin" {
  run bee --batch \
    "bee::load_plugin plugin_1:1.0.0" \
    "bee::load_plugin plugin_2:1.0.0" \
    "env BEE_LOAD_PLUGIN_NAME BEE_LOAD_PLUGIN_PATH BEE_LOAD_PLUGIN_JSON_PATH"
  assert_success
  cat << EOF | assert_output -
# plugin_1 1.0.0 sourced
# plugin_2 1.0.0 sourced
plugin_2
${BATS_TEST_DIRNAME}/fixtures/plugins/plugin_2/1.0.0/plugin_2.bash
${BATS_TEST_DIRNAME}/fixtures/plugins/plugin_2/1.0.0/plugin.json
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
    "bee::load_plugin plugin_1:1.0.0" \
    "bee::load_plugin unknown" \
    "env BEE_LOAD_PLUGIN_NAME BEE_LOAD_PLUGIN_PATH BEE_LOAD_PLUGIN_JSON_PATH"
  assert_success
  assert_output "# plugin_1 1.0.0 sourced"
}

@test "loads plugin dependencies" {
  run bee --batch \
    "bee::load_plugin plugin_with_recursive_deps" \
    "env BEE_LOAD_PLUGIN_NAME BEE_LOAD_PLUGIN_PATH BEE_LOAD_PLUGIN_JSON_PATH"
  assert_success
  cat << EOF | assert_output -
# plugin_with_recursive_deps 1.0.0 sourced
# plugin_with_deps 1.0.0 sourced
# plugin_1 1.0.0 sourced
# plugin_2 1.0.0 sourced
plugin_with_recursive_deps
${BATS_TEST_DIRNAME}/fixtures/plugins/plugin_with_recursive_deps/1.0.0/plugin_with_recursive_deps.bash
${BATS_TEST_DIRNAME}/fixtures/plugins/plugin_with_recursive_deps/1.0.0/plugin.json
EOF
}

@test "fails on missing plugin dependency" {
  run bee --batch \
    "bee::load_plugin plugin_with_missing_deps" \
    "env BEE_LOAD_PLUGIN_NAME"
  assert_failure
  cat << EOF | assert_output -
# plugin_with_missing_deps 1.0.0 sourced
# plugin_with_recursive_deps 1.0.0 sourced
# plugin_with_deps 1.0.0 sourced
# plugin_1 1.0.0 sourced
# plugin_2 1.0.0 sourced
${BEE_ERROR} Missing plugin: 'missing_1:1.0.0'
${BEE_ERROR} Missing plugin: 'missing_2:1.0.0'
EOF
}

@test "runs plugin help when no args" {
  run bee --batch \
    "bee::load_plugin plugin_1" \
    "bee::run_plugin plugin_1"
  assert_success
  cat << 'EOF' | assert_output -
# plugin_1 2.0.0 sourced
plugin_1 2.0.0 help
EOF
}

@test "fails when plugin help is missing" {
  run -127 bee --batch \
    "bee::load_plugin plugin_with_deps" \
    "bee::run_plugin plugin_with_deps"
  assert_failure
  assert_output --partial "plugin_with_deps::help: command not found"
}

@test "runs plugin with args" {
  run bee --batch \
    "bee::load_plugin plugin_1" \
    "bee::run_plugin plugin_1 greet test"
  assert_success
  cat << 'EOF' | assert_output -
# plugin_1 2.0.0 sourced
greeting test from plugin_1 2.0.0
EOF
}

@test "sources optional os file" {
  run bee --batch \
    "bee::load_plugin plugin_1:1.5.0" \
    "bee::run_plugin plugin_1 os test"
  assert_success
  assert_output "os: test"
}

################################################################################
# multiple plugin folders
################################################################################

@test "loads plugin and dependencies from custom folder" {
  # shellcheck disable=SC2030,SC2031
  export TEST_BEE_PLUGINS_PATHS_CUSTOM=1
  run bee bee::load_plugin custom_plugin
  assert_success
  cat << 'EOF' | assert_output -
# custom_plugin 1.0.0 sourced
# plugin_1 1.0.0 sourced
# plugin_2 1.0.0 sourced
EOF
}

@test "loads local plugin and dependencies from custom folder" {
  # shellcheck disable=SC2030,SC2031
  export TEST_BEE_PLUGINS_PATHS_CUSTOM=1
  run bee bee::load_plugin local_plugin
  assert_success
  cat << 'EOF' | assert_output -
# local_plugin sourced
# plugin_1 1.0.0 sourced
# plugin_2 1.0.0 sourced
EOF
}

@test "completes plugins with comp function" {
  assert_comp "bee plugin_with_comp " "comp for plugin_with_comp 1.0.0"
}

@test "completes plugins without comp function" {
  local expected=(greet help)
  assert_comp "bee plugin_2 " "${expected[*]}"
}

@test "only completes first arg for plugins without comp function" {
  assert_comp "bee plugin_2 help "
}

@test "completes mapped plugin version" {
  _create_beefile_with 'BEE_PLUGINS=(plugin_1:1.0.0)'
  local expected=(greet help)
  assert_comp "bee plugin_1 " "${expected[*]}"
}
