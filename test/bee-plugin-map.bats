setup() {
  load 'test-helper'
  _common_setup
  _export_beerc
  _source_beerc
  export TEST_BEE_PLUGINS_PATHS_CUSTOM=1
  _disable_plugin_log
}

@test "maps latest version" {
  run bee bee::map_plugins plugin_1
  assert_success
  assert_output "plugin_1:2.0.0"
}

@test "maps specified version" {
  run bee bee::map_plugins plugin_1:1.0.0
  assert_success
  assert_output "plugin_1:1.0.0"
}

@test "ignores unknown plugin" {
  run bee bee::map_plugins unknown plugin_1
  assert_success
  assert_output "plugin_1:2.0.0"
}

@test "maps multiple plugins" {
  run bee bee::map_plugins plugin_1 plugin_2
  assert_success
  cat << EOF | assert_output -
plugin_1:2.0.0
plugin_2:1.0.0
EOF
}

@test "ignores duplicates with explicit version" {
  run bee bee::map_plugins plugin_1:1.0.0 plugin_1:1.0.0
  assert_success
  cat << EOF | assert_output -
plugin_1:1.0.0
EOF
}

@test "ignores duplicates without version" {
  run bee bee::map_plugins plugin_1 plugin_1
  assert_success
  cat << EOF | assert_output -
plugin_1:2.0.0
EOF
}

@test "maps version for plugin name based on specified version" {
  run bee bee::map_plugins plugin_1:1.0.0 plugin_1
  assert_success
  cat << EOF | assert_output -
plugin_1:1.0.0
EOF
}

@test "doesn't map local plugin, but dependencies " {
  # shellcheck disable=SC2030,SC2031
  export TEST_BEE_PLUGINS_PATHS_CUSTOM=1
  run bee bee::map_plugins local_plugin
  assert_success
  cat << EOF | assert_output -
plugin_1:1.0.0
plugin_2:1.0.0
EOF
}

@test "detects version conflict" {
  run bee bee::map_plugins plugin_1:1.0.0 plugin_1:2.0.0
  assert_success
  cat << EOF | assert_output -
${BEE_WARNING} Version conflicts:
plugin_1:1.0.0 <-> plugin_1:2.0.0
plugin_1:2.0.0
EOF
}

@test "resolves plugins dependencies recursively" {
  run bee bee::map_plugins plugin_with_recursive_deps plugin_1
  assert_success
  cat << EOF | assert_output -
plugin_with_recursive_deps:1.0.0
plugin_with_deps:1.0.0
plugin_1:1.0.0
plugin_2:1.0.0
EOF
}

@test "resolves plugins version specified in dependencies" {
  run bee bee::map_plugins plugin_1 plugin_with_deps
  assert_success
  cat << EOF | assert_output -
plugin_with_deps:1.0.0
plugin_1:1.0.0
plugin_2:1.0.0
EOF
}

@test "runs plugin version specified in Beefile" {
  _create_beefile_with 'BEE_PLUGINS=(plugin_1:1.0.0)'
  run bee --quiet plugin_1
  assert_success
  assert_output "plugin_1 1.0.0 help"
}

@test "runs plugin version specified in dependencies" {
  _create_beefile_with 'BEE_PLUGINS=(plugin_with_deps)'
  run bee --quiet plugin_1
  assert_success
  assert_output "plugin_1 1.0.0 help"
}

@test "runs mapped plugin version" {
  _create_beefile_with 'BEE_PLUGINS=(plugin_1 plugin_1:1.0.0)'
  run bee --quiet plugin_1
  assert_success
  assert_output "plugin_1 1.0.0 help"
}

@test "doesn't keep unmapped sourced plugins" {
  _create_beefile_with 'BEE_PLUGINS=(testplugindepslatest plugin_with_deps)'
  run -127 bee --quiet plugin_1 comp
  assert_failure
  assert_output --partial "plugin_1::comp: command not found"
}
