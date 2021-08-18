setup() {
  load "test-helper.bash"
  load "test-helper-hub.bash"
  _set_beerc
  MODULE_PATH="${PROJECT_ROOT}/src/modules/hub.bash"
}

_setup_empty_bee_hub_repo() {
  mkdir -p "${BATS_TEST_TMPDIR}/$1"
  pushd "${BATS_TEST_TMPDIR}/$1" > /dev/null || exit 1
    echo "empty" > empty.txt
    git init -b main; git add . ; git commit -m "Initial commit"
  popd > /dev/null || exit 1
}

_setup_generic_plugin_repo() {
  mkdir -p "${BATS_TEST_TMPDIR}/plugins"
  cp -r "${BATS_TEST_DIRNAME}/fixtures/plugins/$1/1.0.0/." "${BATS_TEST_TMPDIR}/plugins/$1"
  pushd "${BATS_TEST_TMPDIR}/plugins/$1" > /dev/null || exit 1
    git init -b main; git add . ; git commit -m "Initial commit"; git tag "v1.0.0"
  popd > /dev/null || exit 1
}

_setup_testplugin_repo() {
  _setup_generic_plugin_repo testplugin
  cp -r "${BATS_TEST_DIRNAME}/fixtures/plugins/testplugin/2.0.0/." "${BATS_TEST_TMPDIR}/plugins/testplugin"
  pushd "${BATS_TEST_TMPDIR}/plugins/testplugin" > /dev/null || exit 1
    git add . ; git commit -m "Release 2.0.0"; git tag "v2.0.0"
  popd > /dev/null || exit 1
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
    "file://${BATS_TEST_TMPDIR}/empty1"
    "file://${BATS_TEST_TMPDIR}/empty2"
  )
  _strict bee::hub pull
  run _strict bee::hub install unknown
  assert_failure
  assert_line --index 0 "Installing"
  assert_line --index 1 --partial "✗ unknown"
  assert_line --index 2 "${BEE_ERR} Couldn't install plugin: unknown"
  assert_dir_not_exist "${BEE_CACHES_PATH}/plugins/unknown"
}

@test "finds plugin in correct hub" {
  _setup_empty_bee_hub_repo "empty1"
  _setup_test_bee_hub_repo
  _prepare_module
  BEE_HUBS=(
    "file://${BATS_TEST_TMPDIR}/empty1"
    "file://${BATS_TEST_TMPDIR}/testhub"
  )
  _setup_testplugin_repo
  _strict bee::hub pull

  BEE_HUBS=(
    "file://${BATS_TEST_TMPDIR}/empty1"
    "file://${BATS_TEST_TMPDIR}/testhub"
    "file://${BATS_TEST_TMPDIR}/unknown"
  )
  run _strict bee::hub install testplugin
  assert_success
  assert_line --index 1 --partial "testplugin:2.0.0"
  assert_file_exist "${BEE_CACHES_PATH}/plugins/testplugin/2.0.0/testplugin.bash"
}

@test "installs latest plugin version" {
  _setup_test_bee_hub_repo
  _prepare_module
  BEE_HUBS=("file://${BATS_TEST_TMPDIR}/testhub")
  _setup_testplugin_repo
  _strict bee::hub pull

  run _strict bee::hub install testplugin
  assert_success
  assert_line --index 1 --partial "testplugin:2.0.0"
  assert_file_exist "${BEE_CACHES_PATH}/plugins/testplugin/2.0.0/testplugin.bash"
}

@test "installs specified plugin version" {
  _setup_test_bee_hub_repo
  _prepare_module
  BEE_HUBS=("file://${BATS_TEST_TMPDIR}/testhub")
  _setup_testplugin_repo
  _strict bee::hub pull

  run _strict bee::hub install testplugin:1.0.0
  assert_success
  assert_line --index 1 --partial "testplugin:1.0.0"
  assert_file_exist "${BEE_CACHES_PATH}/plugins/testplugin/1.0.0/testplugin.bash"
}

@test "doesn't install unknown plugin version" {
  _setup_test_bee_hub_repo
  _prepare_module
  BEE_HUBS=("file://${BATS_TEST_TMPDIR}/testhub")
  _setup_testplugin_repo
  _strict bee::hub pull

  run _strict bee::hub install testplugin:9.0.0
  assert_failure
  assert_line --index 0 "Installing"
  assert_line --index 1 --partial "✗ testplugin:9.0.0"
  assert_line --index 2 "${BEE_ERR} Couldn't install plugin: testplugin:9.0.0"
  assert_dir_not_exist "${BEE_CACHES_PATH}/plugins/testplugin"
}

@test "installs multiple plugins" {
  _setup_test_bee_hub_repo
  _prepare_module
  BEE_HUBS=("file://${BATS_TEST_TMPDIR}/testhub")
  _setup_testplugin_repo
  _strict bee::hub pull

  run _strict bee::hub install testplugin:1.0.0 testplugin:2.0.0
  assert_success
  assert_line --index 1 --partial "testplugin:1.0.0"
  assert_line --index 2 --partial "testplugin:2.0.0"
  assert_file_exist "${BEE_CACHES_PATH}/plugins/testplugin/1.0.0/testplugin.bash"
  assert_file_exist "${BEE_CACHES_PATH}/plugins/testplugin/2.0.0/testplugin.bash"
}

@test "installs plugins with dependencies" {
  _setup_test_bee_hub_repo
  _prepare_module
  BEE_HUBS=("file://${BATS_TEST_TMPDIR}/testhub")
  _setup_testplugin_repo
  _setup_generic_plugin_repo othertestplugin
  _setup_generic_plugin_repo testplugindeps
  _strict bee::hub pull

  run _strict bee::hub install testplugindeps
  assert_success
  assert_line --index 1 --partial "testplugindeps:1.0.0"
  assert_line --index 2 --partial "testplugin:1.0.0"
  assert_line --index 3 --partial "othertestplugin:1.0.0"
  assert_file_exist "${BEE_CACHES_PATH}/plugins/testplugindeps/1.0.0/testplugindeps.bash"
  assert_file_exist "${BEE_CACHES_PATH}/plugins/testplugin/1.0.0/testplugin.bash"
  assert_file_exist "${BEE_CACHES_PATH}/plugins/othertestplugin/1.0.0/othertestplugin.bash"
}

@test "skips installing already installed plugins" {
  _setup_test_bee_hub_repo
  _prepare_module
  BEE_HUBS=("file://${BATS_TEST_TMPDIR}/testhub")
  _setup_testplugin_repo
  _strict bee::hub pull
  _strict bee::hub install testplugin

  run _strict bee::hub install testplugin
  assert_success
  refute_line --index 1 --partial "✔︎"
  assert_line --index 1 --partial "testplugin:2.0.0"
  assert_file_exist "${BEE_CACHES_PATH}/plugins/testplugin/2.0.0/testplugin.bash"
}

@test "installs plugins with dependencies recursively" {
  _setup_test_bee_hub_repo
  _prepare_module
  BEE_HUBS=("file://${BATS_TEST_TMPDIR}/testhub")
  _setup_testplugin_repo
  _setup_generic_plugin_repo othertestplugin
  _setup_generic_plugin_repo testplugindeps
  _setup_generic_plugin_repo testplugindepsdep
  _strict bee::hub pull

  run _strict bee::hub install testplugindepsdep testplugin:1.0.0
  assert_success
  assert_line --index 1 --partial "testplugindepsdep:1.0.0"
  assert_line --index 2 --partial "testplugindeps:1.0.0"
  assert_line --index 3 --partial "testplugin:1.0.0"
  assert_line --index 4 --partial "othertestplugin:1.0.0"
  assert_file_exist "${BEE_CACHES_PATH}/plugins/testplugindepsdep/1.0.0/testplugindepsdep.bash"
  assert_file_exist "${BEE_CACHES_PATH}/plugins/testplugindeps/1.0.0/testplugindeps.bash"
  assert_file_exist "${BEE_CACHES_PATH}/plugins/testplugin/1.0.0/testplugin.bash"
  assert_file_exist "${BEE_CACHES_PATH}/plugins/othertestplugin/1.0.0/othertestplugin.bash"
}

@test "fails late when plugins are missing" {
  _setup_test_bee_hub_repo
  _prepare_module
  # shellcheck disable=SC2034
  BEE_HUBS=("file://${BATS_TEST_TMPDIR}/testhub")
  _setup_testplugin_repo
  _setup_generic_plugin_repo othertestplugin
  _setup_generic_plugin_repo testplugindeps
  _setup_generic_plugin_repo testplugindepsdep
  _strict bee::hub pull

  run _strict bee::hub install testpluginmissingdep
  assert_failure
  assert_line --index 1 --partial "testpluginmissingdep:1.0.0"
  assert_line --index 2 --partial "✗ missing:1.0.0"
  assert_line --index 3 --partial "testplugindepsdep:1.0.0"
  assert_line --index 4 --partial "testplugindeps:1.0.0"
  assert_line --index 5 --partial "testplugin:1.0.0"
  assert_line --index 6 --partial "othertestplugin:1.0.0"
  assert_line --index 7 --partial "testplugin:1.0.0"
  assert_line --index 8 --partial "✗ othermissing:1.0.0"
  assert_line --index 9 "${BEE_ERR} Couldn't install plugin: missing:1.0.0"
  assert_line --index 10 "${BEE_ERR} Couldn't install plugin: othermissing:1.0.0"
  assert_file_exist "${BEE_CACHES_PATH}/plugins/testpluginmissingdep/1.0.0/testplugindepsdep.bash"
  assert_file_exist "${BEE_CACHES_PATH}/plugins/testplugindepsdep/1.0.0/testplugindepsdep.bash"
  assert_file_exist "${BEE_CACHES_PATH}/plugins/testplugindeps/1.0.0/testplugindeps.bash"
  assert_file_exist "${BEE_CACHES_PATH}/plugins/testplugin/1.0.0/testplugin.bash"
  assert_file_exist "${BEE_CACHES_PATH}/plugins/othertestplugin/1.0.0/othertestplugin.bash"
}

# TODO if installed plugin exists, check hash to verify it's original
# TODO when installing plugin, check hash to verify it's original
