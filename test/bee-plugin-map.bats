setup() {
  load 'test-helper.bash'
  _set_beerc
  _source_beerc
  export TEST_PLUGIN_QUIET=1
}

@test "maps latest version" {
  run bee bee::map_plugins testplugin
  assert_success
  assert_output "testplugin:2.0.0"
}

@test "maps specified version" {
  run bee bee::map_plugins testplugin:1.0.0
  assert_success
  assert_output "testplugin:1.0.0"
}

@test "ignores unknown plugin" {
  run bee bee::map_plugins unknown testplugin
  assert_success
  assert_output "testplugin:2.0.0"
}

@test "ignores duplicates with explicit version" {
  run bee bee::map_plugins testplugin:1.0.0 testplugin:1.0.0
  assert_success
  cat << EOF | assert_output -
testplugin:1.0.0
EOF
}

@test "ignores duplicates without version" {
  run bee bee::map_plugins testplugin testplugin
  assert_success
  cat << EOF | assert_output -
testplugin:2.0.0
EOF
}

@test "maps version for plugin name based on specified version" {
  run bee bee::map_plugins testplugin:1.0.0 testplugin
  assert_success
  cat << EOF | assert_output -
testplugin:1.0.0
EOF
}

@test "doesn't map local plugin, but dependencies " {
  # shellcheck disable=SC2030,SC2031
  export TEST_BEE_PLUGINS_PATHS_CUSTOM=1
  run bee bee::map_plugins localplugin
  assert_success
  cat << EOF | assert_output -
testplugin:1.0.0
othertestplugin:1.0.0
EOF
}

@test "detects version conflict" {
  run bee bee::map_plugins testplugin:1.0.0 testplugin:2.0.0
  assert_success
  cat << EOF | assert_output -
${BEE_WARN} Version conflicts:
testplugin:1.0.0 <-> testplugin:2.0.0
testplugin:2.0.0
EOF
}

@test "maps multiple plugins" {
  run bee bee::map_plugins testplugin othertestplugin
  assert_success
  cat << EOF | assert_output -
testplugin:2.0.0
othertestplugin:1.0.0
EOF
}

@test "resolves plugins dependencies recursively" {
  run bee bee::map_plugins testplugindepsdep testplugin
  assert_success
  cat << EOF | assert_output -
testplugindepsdep:1.0.0
testplugindeps:1.0.0
testplugin:1.0.0
othertestplugin:1.0.0
EOF
}

@test "resolves plugins version specified in dependencies" {
  run bee bee::map_plugins testplugin testplugindeps
  assert_success
  cat << EOF | assert_output -
testplugindeps:1.0.0
testplugin:1.0.0
othertestplugin:1.0.0
EOF
}

@test "runs plugin version specified in Beefile" {
  # shellcheck disable=SC2030,SC2031
  export TEST_PLUGIN_QUIET=1
  _setup_beefile 'BEE_PLUGINS=(testplugin:1.0.0)'
  run bee --quiet testplugin
  assert_success
  assert_output "testplugin 1.0.0 help"
}

@test "runs plugin version specified in dependencies" {
  # shellcheck disable=SC2030,SC2031
  export TEST_PLUGIN_QUIET=1
  _setup_beefile 'BEE_PLUGINS=(testplugindeps)'
  run bee --quiet testplugin
  assert_success
  assert_output "testplugin 1.0.0 help"
}
