setup() {
  load "test-helper.bash"
  _set_beerc
  MODULE_PATH="${PROJECT_ROOT}/src/modules/hub.bash"
}

teardown() {
  _teardown_test_tmp_dir
}

_prepare_module() {
  _source_bee
  # shellcheck disable=SC1090
  source "${MODULE_PATH}"
}

@test "doesn't install unknown plugin" {
  _setup_empty_bee_hub_repo "empty1"
  _setup_empty_bee_hub_repo "empty2"
  _prepare_module
  BEE_HUBS=(
    "file://${TMP_TEST_DIR}/empty1"
    "file://${TMP_TEST_DIR}/empty2"
  )
  _strict bee::hub pull
  run _strict bee::hub install unknown
  assert_failure
  assert_output "🔴 Couldn't find and install plugin: unknown"
  assert_dir_not_exist "${BEE_CACHES_PATH}/plugins/unknown"
}

@test "installs latest plugin version" {
  _setup_empty_bee_hub_repo "empty1"
  _setup_test_bee_hub_repo
  _prepare_module
  BEE_HUBS=(
    "file://${TMP_TEST_DIR}/empty1"
    "file://${TMP_TEST_DIR}/testhub"
  )
  _setup_testplugin_repo
  _strict bee::hub pull

  BEE_HUBS=(
    "file://${TMP_TEST_DIR}/empty1"
    "file://${TMP_TEST_DIR}/testhub"
    "file://${TMP_TEST_DIR}/unknown"
  )
  run _strict bee::hub install testplugin
  assert_success
  assert_file_exist "${BEE_CACHES_PATH}/plugins/testplugin/2.0.0/testplugin.bash"
}

@test "installs specified plugin version" {
  _setup_empty_bee_hub_repo "empty1"
  _setup_empty_bee_hub_repo "empty2"
  _setup_test_bee_hub_repo
  _prepare_module
  BEE_HUBS=(
    "file://${TMP_TEST_DIR}/empty1"
    "file://${TMP_TEST_DIR}/testhub"
    "file://${TMP_TEST_DIR}/empty2"
  )
  _setup_testplugin_repo
  _strict bee::hub pull

  run _strict bee::hub install testplugin:1.0.0
  assert_success
  assert_file_exist "${BEE_CACHES_PATH}/plugins/testplugin/1.0.0/testplugin.bash"
}

@test "doesn't install unknown plugin version" {
  _setup_empty_bee_hub_repo "empty1"
  _setup_empty_bee_hub_repo "empty2"
  _setup_test_bee_hub_repo
  _prepare_module
  BEE_HUBS=(
    "file://${TMP_TEST_DIR}/empty1"
    "file://${TMP_TEST_DIR}/testhub"
    "file://${TMP_TEST_DIR}/empty2"
  )
  _setup_testplugin_repo
  _strict bee::hub pull
  run _strict bee::hub install testplugin:9.0.0
  assert_failure
  assert_output "🔴 Couldn't find and install plugin: testplugin:9.0.0"
  assert_dir_not_exist "${BEE_CACHES_PATH}/plugins/testplugin"
}

@test "installs multiple plugins" {
  _setup_test_bee_hub_repo
  _prepare_module
  BEE_HUBS=(
    "file://${TMP_TEST_DIR}/testhub"
  )
  _setup_testplugin_repo
  _strict bee::hub pull

  run _strict bee::hub install testplugin:1.0.0 testplugin:2.0.0
  assert_success
  assert_file_exist "${BEE_CACHES_PATH}/plugins/testplugin/1.0.0/testplugin.bash"
  assert_file_exist "${BEE_CACHES_PATH}/plugins/testplugin/2.0.0/testplugin.bash"
}

@test "installs plugins with dependencies" {
  _setup_test_bee_hub_repo
  _prepare_module
  BEE_HUBS=(
    "file://${TMP_TEST_DIR}/testhub"
  )
  _setup_testplugin_repo
  _setup_testplugindeps_repo
  _strict bee::hub pull

  run _strict bee::hub install testplugindeps
  assert_success
  assert_file_exist "${BEE_CACHES_PATH}/plugins/testplugindeps/1.0.0/testplugindeps.bash"
  assert_file_exist "${BEE_CACHES_PATH}/plugins/testplugin/1.0.0/testplugin.bash"
}

@test "skips installing already installed plugins" {
  _setup_test_bee_hub_repo
  _prepare_module
  BEE_HUBS=(
    "file://${TMP_TEST_DIR}/testhub"
  )
  _setup_testplugin_repo
  _strict bee::hub pull
  _strict bee::hub install testplugin

  run _strict bee::hub install testplugin
  assert_success
  assert_file_exist "${BEE_CACHES_PATH}/plugins/testplugin/2.0.0/testplugin.bash"
}

# if installing plugin fails, try all the others, don't exit
# install plugins with all deps recursive
# install plugins with all deps recursive unique, no double installs
# install plugins with circular dependency
# if installed plugin exists, check hash to verify it's original
# when installings plugin, check hash to verify it's original
