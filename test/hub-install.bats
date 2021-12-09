setup() {
  load "test-helper.bash"
  load "test-helper-hub.bash"
  _set_beerc
  _source_beerc
}

@test "doesn't install unknown plugin" {
  run bee install unknown
  assert_failure
  cat << EOF | assert_output -
Installing
└── #E${BEE_CHECK_FAIL} unknown#
${BEE_ERR} Couldn't install plugin: unknown
EOF
  assert_dir_not_exist "${BEE_CACHES_PATH}/plugins/unknown"
}

@test "finds plugin in correct hub" {
  _setup_empty_bee_hub_repo "empty1"
  _setup_test_bee_hub_repo
  _setup_testplugin_repo
  # shellcheck disable=SC2016
  _set_beerc_with 'BEE_HUBS=("file://${BATS_TEST_TMPDIR}/empty1" "file://${BATS_TEST_TMPDIR}/testhub" "file://${BATS_TEST_TMPDIR}/unknown")'
  bee pull
  run bee install testplugin
  assert_success
  cat << EOF | assert_output -
Installing
└── #S${BEE_CHECK_SUCCESS} testplugin:2.0.0 (file://${BATS_TEST_TMPDIR}/testhub)#
EOF
  assert_file_exist "${BEE_CACHES_PATH}/plugins/testplugin/2.0.0/testplugin.bash"
}

@test "installs latest plugin version" {
  _setup_test_bee_hub_repo
  _setup_testplugin_repo
  bee pull
  run bee install testplugin
  assert_success
  cat << EOF | assert_output -
Installing
└── #S${BEE_CHECK_SUCCESS} testplugin:2.0.0 (file://${BATS_TEST_TMPDIR}/testhub)#
EOF
  assert_file_exist "${BEE_CACHES_PATH}/plugins/testplugin/2.0.0/testplugin.bash"
}

@test "installs specified plugin version" {
  _setup_test_bee_hub_repo
  _setup_testplugin_repo
  bee pull
  run bee install testplugin:1.0.0
  assert_success
  cat << EOF | assert_output -
Installing
└── #S${BEE_CHECK_SUCCESS} testplugin:1.0.0 (file://${BATS_TEST_TMPDIR}/testhub)#
EOF
  assert_file_exist "${BEE_CACHES_PATH}/plugins/testplugin/1.0.0/testplugin.bash"
}

@test "doesn't install unknown plugin version" {
  _setup_test_bee_hub_repo
  _setup_testplugin_repo
  bee pull
  run bee install testplugin:9.0.0
  assert_failure
  cat << EOF | assert_output -
Installing
└── #E${BEE_CHECK_FAIL} testplugin:9.0.0#
${BEE_ERR} Couldn't install plugin: testplugin:9.0.0
EOF
  assert_dir_not_exist "${BEE_CACHES_PATH}/plugins/testplugin"
}

@test "installs multiple plugins" {
  _setup_test_bee_hub_repo
  _setup_testplugin_repo
  bee pull
  run bee install testplugin:1.0.0 testplugin:2.0.0
  assert_success
  cat << EOF | assert_output -
Installing
├── #S${BEE_CHECK_SUCCESS} testplugin:1.0.0 (file://${BATS_TEST_TMPDIR}/testhub)#
└── #S${BEE_CHECK_SUCCESS} testplugin:2.0.0 (file://${BATS_TEST_TMPDIR}/testhub)#
EOF
  assert_file_exist "${BEE_CACHES_PATH}/plugins/testplugin/1.0.0/testplugin.bash"
  assert_file_exist "${BEE_CACHES_PATH}/plugins/testplugin/2.0.0/testplugin.bash"
}

@test "installs plugins with dependencies" {
  _setup_test_bee_hub_repo
  _setup_testplugin_repo
  _setup_generic_plugin_repo othertestplugin
  _setup_generic_plugin_repo testplugindeps
  bee pull
  run bee install testplugindeps
  assert_success
  cat << EOF | assert_output -
Installing
└── #S${BEE_CHECK_SUCCESS} testplugindeps:1.0.0 (file://${BATS_TEST_TMPDIR}/testhub)#
    ├── #S${BEE_CHECK_SUCCESS} testplugin:1.0.0 (file://${BATS_TEST_TMPDIR}/testhub)#
    └── #S${BEE_CHECK_SUCCESS} othertestplugin:1.0.0 (file://${BATS_TEST_TMPDIR}/testhub)#
EOF
  assert_file_exist "${BEE_CACHES_PATH}/plugins/testplugindeps/1.0.0/testplugindeps.bash"
  assert_file_exist "${BEE_CACHES_PATH}/plugins/testplugin/1.0.0/testplugin.bash"
  assert_file_exist "${BEE_CACHES_PATH}/plugins/othertestplugin/1.0.0/othertestplugin.bash"
}

@test "skips installing already installed plugins" {
  _setup_test_bee_hub_repo
  _setup_testplugin_repo
  bee pull
  bee install testplugin
  run bee install testplugin
  assert_success
  cat << EOF | assert_output -
Installing
└── testplugin:2.0.0 (file://${BATS_TEST_TMPDIR}/testhub)
EOF
  assert_file_exist "${BEE_CACHES_PATH}/plugins/testplugin/2.0.0/testplugin.bash"
}

@test "installs plugins with dependencies recursively" {
  _setup_test_bee_hub_repo
  _setup_testplugin_repo
  _setup_generic_plugin_repo othertestplugin
  _setup_generic_plugin_repo testplugindeps
  _setup_generic_plugin_repo testplugindepsdep
  bee pull
  run bee install testplugindepsdep testplugin:1.0.0
  assert_success
  cat << EOF | assert_output -
Installing
├── #S${BEE_CHECK_SUCCESS} testplugindepsdep:1.0.0 (file://${BATS_TEST_TMPDIR}/testhub)#
│   ├── #S${BEE_CHECK_SUCCESS} testplugindeps:1.0.0 (file://${BATS_TEST_TMPDIR}/testhub)#
│   │   ├── #S${BEE_CHECK_SUCCESS} testplugin:1.0.0 (file://${BATS_TEST_TMPDIR}/testhub)#
│   │   └── #S${BEE_CHECK_SUCCESS} othertestplugin:1.0.0 (file://${BATS_TEST_TMPDIR}/testhub)#
│   └── testplugin:1.0.0 (file://${BATS_TEST_TMPDIR}/testhub)
└── testplugin:1.0.0 (file://${BATS_TEST_TMPDIR}/testhub)
EOF
  assert_file_exist "${BEE_CACHES_PATH}/plugins/testplugindepsdep/1.0.0/testplugindepsdep.bash"
  assert_file_exist "${BEE_CACHES_PATH}/plugins/testplugindeps/1.0.0/testplugindeps.bash"
  assert_file_exist "${BEE_CACHES_PATH}/plugins/testplugin/1.0.0/testplugin.bash"
  assert_file_exist "${BEE_CACHES_PATH}/plugins/othertestplugin/1.0.0/othertestplugin.bash"
}

@test "fails late when plugins are missing" {
  _setup_test_bee_hub_repo
  _setup_testplugin_repo
  _setup_generic_plugin_repo othertestplugin
  _setup_generic_plugin_repo testplugindeps
  _setup_generic_plugin_repo testplugindepsdep
  _setup_generic_plugin_repo testpluginmissingdep
  bee pull
  run bee install testpluginmissingdep
  assert_failure
  cat << EOF | assert_output -
Installing
└── #S${BEE_CHECK_SUCCESS} testpluginmissingdep:1.0.0 (file://${BATS_TEST_TMPDIR}/testhub)#
    ├── #E${BEE_CHECK_FAIL} missing:1.0.0#
    ├── #S${BEE_CHECK_SUCCESS} testplugindepsdep:1.0.0 (file://${BATS_TEST_TMPDIR}/testhub)#
    │   ├── #S${BEE_CHECK_SUCCESS} testplugindeps:1.0.0 (file://${BATS_TEST_TMPDIR}/testhub)#
    │   │   ├── #S${BEE_CHECK_SUCCESS} testplugin:1.0.0 (file://${BATS_TEST_TMPDIR}/testhub)#
    │   │   └── #S${BEE_CHECK_SUCCESS} othertestplugin:1.0.0 (file://${BATS_TEST_TMPDIR}/testhub)#
    │   └── testplugin:1.0.0 (file://${BATS_TEST_TMPDIR}/testhub)
    └── #E${BEE_CHECK_FAIL} othermissing:1.0.0#
${BEE_ERR} Couldn't install plugin: missing:1.0.0
${BEE_ERR} Couldn't install plugin: othermissing:1.0.0
EOF
  assert_file_exist "${BEE_CACHES_PATH}/plugins/testpluginmissingdep/1.0.0/testpluginmissingdep.bash"
  assert_file_exist "${BEE_CACHES_PATH}/plugins/testplugindepsdep/1.0.0/testplugindepsdep.bash"
  assert_file_exist "${BEE_CACHES_PATH}/plugins/testplugindeps/1.0.0/testplugindeps.bash"
  assert_file_exist "${BEE_CACHES_PATH}/plugins/testplugin/1.0.0/testplugin.bash"
  assert_file_exist "${BEE_CACHES_PATH}/plugins/othertestplugin/1.0.0/othertestplugin.bash"
}

@test "deletes newly installed plugin when hash doesn't match" {
  _setup_test_bee_hub_repo
  _setup_generic_plugin_repo testplugin 0.1.0
  bee pull
  run bee install testplugin:0.1.0
  assert_success
  assert_output --partial "${BEE_ERR} testplugin:0.1.0 sha256 mismatch"
  assert_output --partial "└── #E${BEE_CHECK_FAIL} testplugin:0.1.0 (file://${BATS_TEST_TMPDIR}/testhub)#"
  assert_file_not_exist "${BEE_CACHES_PATH}/plugins/testplugin/0.1.0/testplugin.bash"
}

@test "forces install plugin with wrong hash" {
  _setup_test_bee_hub_repo
  _setup_generic_plugin_repo testplugin 0.1.0
  bee pull
  run bee install --force testplugin:0.1.0
  assert_success
  assert_output --partial "${BEE_WARN} testplugin:0.1.0 sha256 mismatch"
  assert_output --partial "└── #W${BEE_CHECK_SUCCESS} testplugin:0.1.0 (file://${BATS_TEST_TMPDIR}/testhub)#"
  assert_file_exist "${BEE_CACHES_PATH}/plugins/testplugin/0.1.0/testplugin.bash"
}

@test "deletes already installed plugin when hash doesn't match" {
  _setup_test_bee_hub_repo
  _setup_generic_plugin_repo testplugin 0.1.0
  bee pull
  bee install --force testplugin:0.1.0
  run bee install testplugin:0.1.0
  assert_success
  assert_output --partial "${BEE_ERR} testplugin:0.1.0 sha256 mismatch"
  assert_output --partial "└── #E${BEE_CHECK_FAIL} testplugin:0.1.0 (file://${BATS_TEST_TMPDIR}/testhub)#"
  assert_file_not_exist "${BEE_CACHES_PATH}/plugins/testplugin/0.1.0/testplugin.bash"
}
