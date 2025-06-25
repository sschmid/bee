setup() {
  load 'test-helper'
  _common_setup
  _export_beerc
  cd "${BATS_TEST_TMPDIR}" || exit
}

@test "shows help when no args" {
  run bee res
  assert_failure
  assert_bee_help
}

@test "doesn't copy plugin resources if they don't exist" {
  run bee res plugin_1
  assert_success
  refute_output
  assert_dir_not_exist "${BATS_TEST_TMPDIR}/plugin_1"
}

@test "copies plugin resources" {
  run bee res plugin_1:1.6.0
  assert_success
  assert_output "Copying resources into .bee/plugin_1"
  assert_file_exist "${BATS_TEST_TMPDIR}/.bee/plugin_1/file1"
}

@test "copies multiple plugin resources" {
  run bee res plugin_1:1.6.0 plugin_1:1.7.0
  assert_success
  cat << 'EOF' | assert_output -
Copying resources into .bee/plugin_1
Copying resources into .bee/plugin_1
EOF
  assert_file_exist "${BATS_TEST_TMPDIR}/.bee/plugin_1/file1"
  assert_file_exist "${BATS_TEST_TMPDIR}/.bee/plugin_1/file2"
}

@test "copies plugin resources of mapped plugin version" {
  _create_beefile_with 'BEE_PLUGINS=(plugin_1:1.6.0)'
  run bee res plugin_1
  assert_success
  assert_output "Copying resources into .bee/plugin_1"
  assert_file_exist "${BATS_TEST_TMPDIR}/.bee/plugin_1/file1"
}

@test "completes bee res with plugins" {
  _create_bee_hub_repo "${TEST_HUB_1}"
  bee pull
  assert_comp "bee res " "${ALL_TEST_PLUGINS[*]}"
}

@test "completes bee res with multiple plugins" {
  _create_bee_hub_repo "${TEST_HUB_1}"
  bee pull
  assert_comp "bee res myplugin " "${ALL_TEST_PLUGINS[*]}"
}
