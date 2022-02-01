setup() {
  load "test-helper.bash"
  load "test-helper-hub.bash"
  _set_beerc
  cd "${BATS_TEST_TMPDIR}" || exit
}

@test "shows help when no args" {
  run bee res
  assert_bee_help
}

@test "doesn't copy plugin resources if they don't exist" {
  run bee res testplugin
  assert_success
  refute_output
  assert_dir_not_exist "${BATS_TEST_TMPDIR}/testplugin"
}

@test "copies plugin resources" {
  run bee res testplugin:1.6.0
  assert_success
  assert_output "Copying resources into .bee/testplugin"
  assert_file_exist "${BATS_TEST_TMPDIR}/.bee/testplugin/file1"
}

@test "copies multiple plugin resources" {
  run bee res testplugin:1.6.0 testplugin:1.7.0
  assert_success
  cat << 'EOF' | assert_output -
Copying resources into .bee/testplugin
Copying resources into .bee/testplugin
EOF
  assert_file_exist "${BATS_TEST_TMPDIR}/.bee/testplugin/file1"
  assert_file_exist "${BATS_TEST_TMPDIR}/.bee/testplugin/file2"
}

@test "copies plugin resources of mapped plugin version" {
  _setup_beefile 'BEE_PLUGINS=(testplugin:1.6.0)'
  run bee res testplugin
  assert_success
  assert_output "Copying resources into .bee/testplugin"
  assert_file_exist "${BATS_TEST_TMPDIR}/.bee/testplugin/file1"
}

@test "completes bee res with plugins" {
  _setup_test_bee_hub_repo
  bee pull
  local expected=(othertestplugin testplugin testplugindeps testplugindepsdep testpluginmissingdep)
  assert_comp "bee res " "${expected[*]}"
}

@test "completes bee res with multiple plugins" {
  _setup_test_bee_hub_repo
  bee pull
  local expected=(othertestplugin testplugin testplugindeps testplugindepsdep testpluginmissingdep)
  assert_comp "bee res myplugin " "${expected[*]}"
}
