setup() {
  load 'test-helper.bash'
  _set_beerc
  _source_beerc
}

@test "resolves latest version" {
  run bee bee::map_plugins testplugin
  assert_success
  assert_output "testplugin:2.0.0"
}

@test "sets specified version" {
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

@test "resolves version for plugin name based on specified version" {
  run bee bee::map_plugins testplugin:1.0.0 testplugin
  assert_success
  assert_output "testplugin:1.0.0"
}

@test "detects version conflict" {
  run bee bee::map_plugins testplugin:1.0.0 testplugin:2.0.0
  assert_failure
  cat << EOF | assert_output -
${BEE_ERR} Version conflicts:
testplugin:1.0.0 <-> testplugin:2.0.0
EOF
}

@test "resolves multiple plugins" {
  run bee bee::map_plugins testplugindepsdep testplugindeps
  assert_success
  cat << EOF | assert_output -
testplugindepsdep:1.0.0
testplugindeps:1.0.0
EOF
}
