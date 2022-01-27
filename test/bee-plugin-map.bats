setup() {
  load 'test-helper.bash'
  _set_beerc
  _source_beerc
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

@test "doesn't ignore duplicates with explicit version" {
  run bee bee::map_plugins testplugin:1.0.0 testplugin:1.0.0
  assert_success
  cat << EOF | assert_output -
testplugin:1.0.0
testplugin:1.0.0
EOF
}

@test "doesn't ignore duplicates without version" {
  run bee bee::map_plugins testplugin testplugin
  assert_success
  cat << EOF | assert_output -
testplugin:2.0.0
testplugin:2.0.0
EOF
}

@test "maps version for plugin name based on specified version" {
  run bee bee::map_plugins testplugin:1.0.0 testplugin
  assert_success
  cat << EOF | assert_output -
testplugin:1.0.0
testplugin:1.0.0
EOF
}

@test "doesn't map local plugin " {
  # shellcheck disable=SC2031
  export TEST_BEE_PLUGINS_PATHS_CUSTOM=1
  run bee bee::map_plugins localplugin
  assert_success
  refute_output
}

@test "detects version conflict" {
  run bee bee::map_plugins testplugin:1.0.0 testplugin:2.0.0
  assert_failure
  cat << EOF | assert_output -
${BEE_ERR} Version conflicts:
testplugin:1.0.0 <-> testplugin:2.0.0
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

@test "runs plugin version specified in Beefile" {
  export TEST_PLUGIN_QUIET=1
  _setup_beefile 'BEE_PLUGINS=(testplugin:1.0.0)'
  run bee --quiet testplugin
  assert_success
  assert_output "testplugin 1.0.0 help"
}
