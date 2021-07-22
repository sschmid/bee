setup() {
  load "test-helper.bash"
  _set_beerc
  MODULE_PATH="${PROJECT_ROOT}/src/modules/hub.bash"
}

teardown() {
  _teardown_test_tmp_dir
}

@test "is not executable" {
  assert_file_not_executable "${MODULE_PATH}"
}

@test "shows help when not enough args" {
  run bee hub
  assert_output --partial "plugin-based bash automation"

  run bee hub unknown
  assert_output --partial "plugin-based bash automation"
}

_prepare_module() {
  _source_bee
  # shellcheck disable=SC1090
  source "${MODULE_PATH}"
}

@test "file:// to cache path" {
  _prepare_module
  run _strict bee::hub::to_cache_path 'file://${HOME}/bee/beehub'
  assert_success
  assert_output "${BEE_HUBS_CACHE_PATH}/beehub"
}

@test "https:// to cache path" {
  _prepare_module
  run _strict bee::hub::to_cache_path "https://github.com/sschmid/beehub.git"
  assert_success
  assert_output "${BEE_HUBS_CACHE_PATH}/github.com/sschmid/beehub"
}

@test "git@ to cache path" {
  _prepare_module
  run _strict bee::hub::to_cache_path "git@github.com:sschmid/beehub.git"
  assert_success
  assert_output "${BEE_HUBS_CACHE_PATH}/github.com/sschmid/beehub"
}

@test "unsupported url" {
  _prepare_module
  run _strict bee::hub::to_cache_path "unknown"
  assert_success
  refute_output
}

@test "clones all registered hubs" {
  _setup_test_bee_hub1_repo
  _setup_test_bee_hub2_repo
  _prepare_module
  BEE_HUBS=(
    "file://${TMP_TEST_DIR}/testbeehub1"
    "file://${TMP_TEST_DIR}/testbeehub2"
  )
  run _strict bee::hub update
  assert_success

  [ -d "${BEE_HUBS_CACHE_PATH}/testbeehub1" ]
  [ -f "${BEE_HUBS_CACHE_PATH}/testbeehub1/testplugin/1.0.0/plugin.bash" ]
  [ -d "${BEE_HUBS_CACHE_PATH}/testbeehub2" ]
  [ -f "${BEE_HUBS_CACHE_PATH}/testbeehub2/othertestplugin/1.0.0/plugin.bash" ]
}

@test "skips invalid hub url" {
  _setup_test_bee_hub1_repo
  _setup_test_bee_hub2_repo
  _prepare_module
  BEE_HUBS=(
    "file://${TMP_TEST_DIR}/testbeehub1"
    "unknown"
    "file://${TMP_TEST_DIR}/testbeehub2"
  )
  run _strict bee::hub update
  assert_success

  [ -d "${BEE_HUBS_CACHE_PATH}/testbeehub1" ]
  [ -f "${BEE_HUBS_CACHE_PATH}/testbeehub1/testplugin/1.0.0/plugin.bash" ]
  [ -d "${BEE_HUBS_CACHE_PATH}/testbeehub2" ]
  [ -f "${BEE_HUBS_CACHE_PATH}/testbeehub2/othertestplugin/1.0.0/plugin.bash" ]
}

@test "updates existing hubs" {
  _setup_test_bee_hub1_repo
  _setup_test_bee_hub2_repo
  _prepare_module
  BEE_HUBS=(
    "file://${TMP_TEST_DIR}/testbeehub1"
    "file://${TMP_TEST_DIR}/testbeehub2"
  )
  bee::hub update
  [ ! -f "${BEE_HUBS_CACHE_PATH}/testbeehub1/testplugin/2.0.0/plugin.bash" ]

  _update_test_bee_hub1_repo
  run _strict bee::hub update
  assert_success
  [ -f "${BEE_HUBS_CACHE_PATH}/testbeehub1/testplugin/2.0.0/plugin.bash" ]
}

