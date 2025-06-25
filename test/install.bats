setup() {
  load 'test-helper'
  _common_setup
  _export_beerc
  export TEST_BEE_PLUGINS_NEED_INSTALL=1
  _source_beerc
}

@test "doesn't install unknown plugin" {
  bee pull
  run bee install unknown
  assert_failure
  cat << EOF | assert_output -
Installing
└── #E${BEE_CHECK_FAIL} unknown#
${BEE_ERROR} Couldn't install plugin: unknown
EOF
  assert_dir_not_exist "${BEE_CACHE_PATH}/plugins/unknown"
}

@test "pulls before installing" {
  _create_bee_hub_repo "${TEST_HUB_1}"
  _create_plugin_repo
  # shellcheck disable=SC2016
  _export_beerc_with 'BEE_HUBS=("file://${BATS_TEST_TMPDIR}/${TEST_HUB_1}")'
  run bee install plugin_1
  assert_success
  BEE_HUBS_CACHE_PATH="${BEE_CACHE_PATH}/hubs"
  assert_file_exist "${BEE_HUBS_CACHE_PATH}/${TEST_HUB_1}/plugin_1/2.0.0/plugin.json"
}

@test "finds plugin in correct hub" {
  _create_empty_bee_hub_repo "empty"
  _create_bee_hub_repo "${TEST_HUB_1}"
  _create_plugin_repo
  # shellcheck disable=SC2016
  _export_beerc_with 'BEE_HUBS=("file://${BATS_TEST_TMPDIR}/empty" "file://${BATS_TEST_TMPDIR}/${TEST_HUB_1}" "file://${BATS_TEST_TMPDIR}/unknown")'
  bee pull
  run bee install plugin_1
  assert_success
  cat << EOF | assert_output -
Installing
└── #S${BEE_CHECK_SUCCESS} plugin_1:2.0.0 (file://${BATS_TEST_TMPDIR}/${TEST_HUB_1})#
EOF
  assert_file_exist "${BEE_CACHE_PATH}/plugins/plugin_1/2.0.0/plugin_1.bash"
}

@test "installs latest plugin version" {
  _create_bee_hub_repo "${TEST_HUB_1}"
  _create_plugin_repo
  bee pull
  run bee install plugin_1
  assert_success
  cat << EOF | assert_output -
Installing
└── #S${BEE_CHECK_SUCCESS} plugin_1:2.0.0 (file://${BATS_TEST_TMPDIR}/${TEST_HUB_1})#
EOF
  assert_file_exist "${BEE_CACHE_PATH}/plugins/plugin_1/2.0.0/plugin_1.bash"
}

@test "installs specified plugin version" {
  _create_bee_hub_repo "${TEST_HUB_1}"
  _create_plugin_repo
  bee pull
  run bee install plugin_1:1.0.0
  assert_success
  cat << EOF | assert_output -
Installing
└── #S${BEE_CHECK_SUCCESS} plugin_1:1.0.0 (file://${BATS_TEST_TMPDIR}/${TEST_HUB_1})#
EOF
  assert_file_exist "${BEE_CACHE_PATH}/plugins/plugin_1/1.0.0/plugin_1.bash"
}

@test "doesn't install unknown plugin version" {
  _create_bee_hub_repo "${TEST_HUB_1}"
  _create_plugin_repo
  bee pull
  run bee install plugin_1:9.0.0
  assert_failure
  cat << EOF | assert_output -
Installing
└── #E${BEE_CHECK_FAIL} plugin_1:9.0.0#
${BEE_ERROR} Couldn't install plugin: plugin_1:9.0.0
EOF
  assert_dir_not_exist "${BEE_CACHE_PATH}/plugins/plugin_1"
}

@test "installs multiple plugins" {
  _create_bee_hub_repo "${TEST_HUB_1}"
  _create_plugin_repo
  bee pull
  run bee install plugin_1:1.0.0 plugin_1:2.0.0
  assert_success
  cat << EOF | assert_output -
Installing
├── #S${BEE_CHECK_SUCCESS} plugin_1:1.0.0 (file://${BATS_TEST_TMPDIR}/${TEST_HUB_1})#
└── #S${BEE_CHECK_SUCCESS} plugin_1:2.0.0 (file://${BATS_TEST_TMPDIR}/${TEST_HUB_1})#
EOF
  assert_file_exist "${BEE_CACHE_PATH}/plugins/plugin_1/1.0.0/plugin_1.bash"
  assert_file_exist "${BEE_CACHE_PATH}/plugins/plugin_1/2.0.0/plugin_1.bash"
}

@test "installs plugins with dependencies" {
  _create_bee_hub_repo "${TEST_HUB_1}"
  _create_plugin_repo
  _create_generic_plugin_repo plugin_2
  _create_generic_plugin_repo plugin_with_deps
  bee pull
  run bee install plugin_with_deps
  assert_success
  cat << EOF | assert_output -
Installing
└── #S${BEE_CHECK_SUCCESS} plugin_with_deps:1.0.0 (file://${BATS_TEST_TMPDIR}/${TEST_HUB_1})#
    ├── #S${BEE_CHECK_SUCCESS} plugin_1:1.0.0 (file://${BATS_TEST_TMPDIR}/${TEST_HUB_1})#
    └── #S${BEE_CHECK_SUCCESS} plugin_2:1.0.0 (file://${BATS_TEST_TMPDIR}/${TEST_HUB_1})#
EOF
  assert_file_exist "${BEE_CACHE_PATH}/plugins/plugin_with_deps/1.0.0/plugin_with_deps.bash"
  assert_file_exist "${BEE_CACHE_PATH}/plugins/plugin_1/1.0.0/plugin_1.bash"
  assert_file_exist "${BEE_CACHE_PATH}/plugins/plugin_2/1.0.0/plugin_2.bash"
}

@test "skips installing already installed plugins" {
  _create_bee_hub_repo "${TEST_HUB_1}"
  _create_plugin_repo
  bee pull
  bee install plugin_1
  run bee install plugin_1
  assert_success
  cat << EOF | assert_output -
Installing
└── plugin_1:2.0.0 (file://${BATS_TEST_TMPDIR}/${TEST_HUB_1})
EOF
  assert_file_exist "${BEE_CACHE_PATH}/plugins/plugin_1/2.0.0/plugin_1.bash"
}

@test "installs plugins with dependencies recursively" {
  _create_bee_hub_repo "${TEST_HUB_1}"
  _create_plugin_repo
  _create_generic_plugin_repo plugin_2
  _create_generic_plugin_repo plugin_with_deps
  _create_generic_plugin_repo plugin_with_deps_on_deps
  bee pull
  run bee install plugin_with_deps_on_deps plugin_1:1.0.0
  assert_success
  cat << EOF | assert_output -
Installing
├── #S${BEE_CHECK_SUCCESS} plugin_with_deps_on_deps:1.0.0 (file://${BATS_TEST_TMPDIR}/${TEST_HUB_1})#
│   ├── #S${BEE_CHECK_SUCCESS} plugin_with_deps:1.0.0 (file://${BATS_TEST_TMPDIR}/${TEST_HUB_1})#
│   │   ├── #S${BEE_CHECK_SUCCESS} plugin_1:1.0.0 (file://${BATS_TEST_TMPDIR}/${TEST_HUB_1})#
│   │   └── #S${BEE_CHECK_SUCCESS} plugin_2:1.0.0 (file://${BATS_TEST_TMPDIR}/${TEST_HUB_1})#
│   └── plugin_1:1.0.0 (file://${BATS_TEST_TMPDIR}/${TEST_HUB_1})
└── plugin_1:1.0.0 (file://${BATS_TEST_TMPDIR}/${TEST_HUB_1})
EOF
  assert_file_exist "${BEE_CACHE_PATH}/plugins/plugin_with_deps_on_deps/1.0.0/plugin_with_deps_on_deps.bash"
  assert_file_exist "${BEE_CACHE_PATH}/plugins/plugin_with_deps/1.0.0/plugin_with_deps.bash"
  assert_file_exist "${BEE_CACHE_PATH}/plugins/plugin_1/1.0.0/plugin_1.bash"
  assert_file_exist "${BEE_CACHE_PATH}/plugins/plugin_2/1.0.0/plugin_2.bash"
}

@test "installs local plugins with dependencies recursively" {
  _disable_plugin_log
  _create_bee_hub_repo "${TEST_HUB_1}"
  _create_plugin_repo
  _create_generic_plugin_repo plugin_2
  bee pull
  run bee install local_plugin
  assert_success
  cat << EOF | assert_output -
Installing
└── local_plugin:local (${BATS_TEST_DIRNAME}/fixtures/custom_plugins/local_plugin/local_plugin.bash)
    ├── #S${BEE_CHECK_SUCCESS} plugin_1:1.0.0 (file://${BATS_TEST_TMPDIR}/${TEST_HUB_1})#
    └── #S${BEE_CHECK_SUCCESS} plugin_2:1.0.0 (file://${BATS_TEST_TMPDIR}/${TEST_HUB_1})#
EOF
  assert_file_exist "${BEE_CACHE_PATH}/plugins/plugin_1/1.0.0/plugin_1.bash"
}

@test "installs local plugins with local tag with dependencies recursively" {
  _disable_plugin_log
  _create_bee_hub_repo "${TEST_HUB_1}"
  _create_plugin_repo
  _create_generic_plugin_repo plugin_2
  bee pull
  run bee install local_plugin:local
  assert_success
  cat << EOF | assert_output -
Installing
└── local_plugin:local (${BATS_TEST_DIRNAME}/fixtures/custom_plugins/local_plugin/local_plugin.bash)
    ├── #S${BEE_CHECK_SUCCESS} plugin_1:1.0.0 (file://${BATS_TEST_TMPDIR}/${TEST_HUB_1})#
    └── #S${BEE_CHECK_SUCCESS} plugin_2:1.0.0 (file://${BATS_TEST_TMPDIR}/${TEST_HUB_1})#
EOF
  assert_file_exist "${BEE_CACHE_PATH}/plugins/plugin_1/1.0.0/plugin_1.bash"
}

@test "fails late when plugins are missing" {
  _create_bee_hub_repo "${TEST_HUB_1}"
  _create_plugin_repo
  _create_generic_plugin_repo plugin_2
  _create_generic_plugin_repo plugin_with_deps
  _create_generic_plugin_repo plugin_with_deps_on_deps
  _create_generic_plugin_repo plugin_with_missing_deps
  bee pull
  run bee install plugin_with_missing_deps
  assert_failure
  cat << EOF | assert_output -
Installing
└── #S${BEE_CHECK_SUCCESS} plugin_with_missing_deps:1.0.0 (file://${BATS_TEST_TMPDIR}/${TEST_HUB_1})#
    ├── #E${BEE_CHECK_FAIL} missing:1.0.0#
    ├── #S${BEE_CHECK_SUCCESS} plugin_with_deps_on_deps:1.0.0 (file://${BATS_TEST_TMPDIR}/${TEST_HUB_1})#
    │   ├── #S${BEE_CHECK_SUCCESS} plugin_with_deps:1.0.0 (file://${BATS_TEST_TMPDIR}/${TEST_HUB_1})#
    │   │   ├── #S${BEE_CHECK_SUCCESS} plugin_1:1.0.0 (file://${BATS_TEST_TMPDIR}/${TEST_HUB_1})#
    │   │   └── #S${BEE_CHECK_SUCCESS} plugin_2:1.0.0 (file://${BATS_TEST_TMPDIR}/${TEST_HUB_1})#
    │   └── plugin_1:1.0.0 (file://${BATS_TEST_TMPDIR}/${TEST_HUB_1})
    └── #E${BEE_CHECK_FAIL} othermissing:1.0.0#
${BEE_ERROR} Couldn't install plugin: missing:1.0.0
${BEE_ERROR} Couldn't install plugin: othermissing:1.0.0
EOF
  assert_file_exist "${BEE_CACHE_PATH}/plugins/plugin_with_missing_deps/1.0.0/plugin_with_missing_deps.bash"
  assert_file_exist "${BEE_CACHE_PATH}/plugins/plugin_with_deps_on_deps/1.0.0/plugin_with_deps_on_deps.bash"
  assert_file_exist "${BEE_CACHE_PATH}/plugins/plugin_with_deps/1.0.0/plugin_with_deps.bash"
  assert_file_exist "${BEE_CACHE_PATH}/plugins/plugin_1/1.0.0/plugin_1.bash"
  assert_file_exist "${BEE_CACHE_PATH}/plugins/plugin_2/1.0.0/plugin_2.bash"
}

@test "deletes newly installed plugin when hash doesn't match" {
  _create_bee_hub_repo "${TEST_HUB_1}"
  _create_generic_plugin_repo plugin_wrong_hash 1.0.0
  bee pull
  run bee install plugin_wrong_hash:1.0.0
  assert_success
  assert_output --partial "${BEE_ERROR} plugin_wrong_hash:1.0.0 sha256 mismatch"
  assert_output --partial "└── #E${BEE_CHECK_FAIL} plugin_wrong_hash:1.0.0 (file://${BATS_TEST_TMPDIR}/${TEST_HUB_1})#"
  assert_file_not_exist "${BEE_CACHE_PATH}/plugins/plugin_wrong_hash/1.0.0/plugin_wrong_hash.bash"
}

@test "forces install plugin with wrong hash" {
  _create_bee_hub_repo "${TEST_HUB_1}"
  _create_generic_plugin_repo plugin_wrong_hash 1.0.0
  bee pull
  run bee install --force plugin_wrong_hash:1.0.0
  assert_success
  assert_output --partial "${BEE_WARNING} plugin_wrong_hash:1.0.0 sha256 mismatch"
  assert_output --partial "└── #W${BEE_CHECK_SUCCESS} plugin_wrong_hash:1.0.0 (file://${BATS_TEST_TMPDIR}/${TEST_HUB_1})#"
  assert_file_exist "${BEE_CACHE_PATH}/plugins/plugin_wrong_hash/1.0.0/plugin_wrong_hash.bash"
}

@test "deletes already installed plugin when hash doesn't match" {
  _create_bee_hub_repo "${TEST_HUB_1}"
  _create_generic_plugin_repo plugin_wrong_hash 1.0.0
  bee pull
  bee install --force plugin_wrong_hash:1.0.0
  run bee install plugin_wrong_hash:1.0.0
  assert_success
  assert_output --partial "${BEE_ERROR} plugin_wrong_hash:1.0.0 sha256 mismatch"
  assert_output --partial "└── #E${BEE_CHECK_FAIL} plugin_wrong_hash:1.0.0 (file://${BATS_TEST_TMPDIR}/${TEST_HUB_1})#"
  assert_file_not_exist "${BEE_CACHE_PATH}/plugins/plugin_wrong_hash/1.0.0/plugin_wrong_hash.bash"
}

@test "installs plugins from Beefile" {
  _create_bee_hub_repo "${TEST_HUB_1}"
  _create_plugin_repo
  _create_generic_plugin_repo plugin_2
  _create_generic_plugin_repo plugin_with_deps
  _create_generic_plugin_repo plugin_with_deps_on_deps
  _create_beefile_with 'BEE_PLUGINS=(plugin_with_deps_on_deps plugin_1)'
  bee pull
  run bee install
  assert_success
  cat << EOF | assert_output -
Installing plugins based on ${BATS_TEST_TMPDIR}/Beefile
├── #S${BEE_CHECK_SUCCESS} plugin_with_deps_on_deps:1.0.0 (file://${BATS_TEST_TMPDIR}/${TEST_HUB_1})#
│   ├── #S${BEE_CHECK_SUCCESS} plugin_with_deps:1.0.0 (file://${BATS_TEST_TMPDIR}/${TEST_HUB_1})#
│   │   ├── #S${BEE_CHECK_SUCCESS} plugin_1:1.0.0 (file://${BATS_TEST_TMPDIR}/${TEST_HUB_1})#
│   │   └── #S${BEE_CHECK_SUCCESS} plugin_2:1.0.0 (file://${BATS_TEST_TMPDIR}/${TEST_HUB_1})#
│   └── plugin_1:1.0.0 (file://${BATS_TEST_TMPDIR}/${TEST_HUB_1})
└── #S${BEE_CHECK_SUCCESS} plugin_1:2.0.0 (file://${BATS_TEST_TMPDIR}/${TEST_HUB_1})#
EOF
  assert_file_exist "${BEE_CACHE_PATH}/plugins/plugin_with_deps_on_deps/1.0.0/plugin_with_deps_on_deps.bash"
  assert_file_exist "${BEE_CACHE_PATH}/plugins/plugin_with_deps/1.0.0/plugin_with_deps.bash"
  assert_file_exist "${BEE_CACHE_PATH}/plugins/plugin_1/1.0.0/plugin_1.bash"
  assert_file_exist "${BEE_CACHE_PATH}/plugins/plugin_2/1.0.0/plugin_2.bash"
}

@test "completes bee install with options and plugins" {
  _create_bee_hub_repo "${TEST_HUB_1}"
  bee pull
  assert_comp "bee install " "--force ${ALL_TEST_PLUGINS[*]}"
}

@test "completes bee install with multiple plugins" {
  _create_bee_hub_repo "${TEST_HUB_1}"
  bee pull
  assert_comp "bee install myplugin " "${ALL_TEST_PLUGINS[*]}"
}
