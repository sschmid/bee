setup() {
  load "test-helper.bash"
  load "test-helper-hub.bash"
  _set_beerc
  MODULE_PATH="${PROJECT_ROOT}/src/modules/hub.bash"
}

_setup_mock_bee_hub_repo() {
  mkdir -p "${BATS_TEST_TMPDIR}/$1/$2/1.0.0"
  pushd "${BATS_TEST_TMPDIR}/$1" > /dev/null || exit 1
    touch "$2/1.0.0/spec.json"
    git init -b main; git add . ; git commit -m "Initial commit"
  popd > /dev/null || exit 1
}

_update_mock_bee_hub_repo() {
  mkdir -p "${BATS_TEST_TMPDIR}/$1/$2/$3"
  pushd "${BATS_TEST_TMPDIR}/$1" > /dev/null || exit 1
    touch "$2/$3/spec.json"; git add . ; git commit -m "Release $3"
  popd > /dev/null || exit 1
}

@test "is not executable" {
  assert_file_not_executable "${MODULE_PATH}"
}

@test "shows help when not enough args" {
  run bee hub
  assert_bee_help

  run bee hub unknown
  assert_bee_help
}

_prepare_module() {
  _source_bee
  # shellcheck disable=SC1090
  source "${MODULE_PATH}"
}

@test "file:// to cache path" {
  _prepare_module
  # shellcheck disable=SC2016
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

@test "git:// to cache path" {
  _prepare_module
  run _strict bee::hub::to_cache_path "git://github.com/sschmid/beehub"
  assert_success
  assert_output "${BEE_HUBS_CACHE_PATH}/github.com/sschmid/beehub"
}

@test "git@ to cache path" {
  _prepare_module
  run _strict bee::hub::to_cache_path "git@github.com:sschmid/beehub.git"
  assert_success
  assert_output "${BEE_HUBS_CACHE_PATH}/github.com/sschmid/beehub"
}

@test "ssh:// to cache path" {
  _prepare_module
  run _strict bee::hub::to_cache_path "ssh://git@github.com/sschmid/beehub"
  assert_success
  assert_output "${BEE_HUBS_CACHE_PATH}/github.com/sschmid/beehub"
}

@test "warns when unsupported url" {
  _prepare_module
  run _strict bee::hub::to_cache_path "unknown"
  assert_success
  assert_output "${BEE_WARN} Unsupported hub url: unknown"
}

@test "clones all registered hubs" {
  _setup_mock_bee_hub_repo testbeehub1 testplugin
  _setup_mock_bee_hub_repo testbeehub2 othertestplugin
  _prepare_module
  BEE_HUBS=(
    "file://${BATS_TEST_TMPDIR}/testbeehub1"
    "file://${BATS_TEST_TMPDIR}/testbeehub2"
  )
  run _strict bee::hub pull
  assert_success

  assert_file_exist "${BEE_HUBS_CACHE_PATH}/testbeehub1/testplugin/1.0.0/spec.json"
  assert_file_exist "${BEE_HUBS_CACHE_PATH}/testbeehub2/othertestplugin/1.0.0/spec.json"
}

@test "clones specified hubs" {
  _setup_mock_bee_hub_repo testbeehub1 testplugin
  _setup_mock_bee_hub_repo testbeehub2 othertestplugin
  _prepare_module
  BEE_HUBS=(
    "file://${BATS_TEST_TMPDIR}/testbeehub1"
    "file://${BATS_TEST_TMPDIR}/testbeehub2"
  )
  run _strict bee::hub pull "file://${BATS_TEST_TMPDIR}/testbeehub1"
  assert_success

  assert_file_exist "${BEE_HUBS_CACHE_PATH}/testbeehub1/testplugin/1.0.0/spec.json"
  assert_dir_not_exist "${BEE_HUBS_CACHE_PATH}/testbeehub2"
}

@test "ignores cloning unknown hubs" {
  _setup_mock_bee_hub_repo testbeehub1 testplugin
  _setup_mock_bee_hub_repo testbeehub2 othertestplugin
  _prepare_module
  BEE_HUBS=(
    "file://${BATS_TEST_TMPDIR}/testbeehub1"
    "unknown"
    "file://${BATS_TEST_TMPDIR}/testbeehub2"
  )
  run _strict bee::hub pull
  assert_success
  assert_output --partial "${BEE_WARN} Unsupported hub url: unknown"

  assert_file_exist "${BEE_HUBS_CACHE_PATH}/testbeehub1/testplugin/1.0.0/spec.json"
  assert_dir_not_exist "${BEE_HUBS_CACHE_PATH}/unknown"
  assert_file_exist "${BEE_HUBS_CACHE_PATH}/testbeehub2/othertestplugin/1.0.0/spec.json"
}

@test "pulls existing hubs" {
  _setup_mock_bee_hub_repo testbeehub1 testplugin
  _setup_mock_bee_hub_repo testbeehub2 othertestplugin
  _prepare_module
  BEE_HUBS=(
    "file://${BATS_TEST_TMPDIR}/testbeehub1"
    "file://${BATS_TEST_TMPDIR}/testbeehub2"
  )
  bee::hub pull
  assert_file_not_exist "${BEE_HUBS_CACHE_PATH}/testbeehub1/testplugin/2.0.0/spec.json"

  _update_mock_bee_hub_repo testbeehub1 testplugin 2.0.0
  run _strict bee::hub pull
  assert_success
  assert_file_exist "${BEE_HUBS_CACHE_PATH}/testbeehub1/testplugin/2.0.0/spec.json"
}

@test "pulls test hub" {
  _setup_test_bee_hub_repo
  _prepare_module
  BEE_HUBS=(
    "file://${BATS_TEST_TMPDIR}/testhub"
  )
  run _strict bee::hub pull

  assert_file_exist "${BEE_HUBS_CACHE_PATH}/testhub/testplugin/1.0.0/spec.json"
  assert_file_exist "${BEE_HUBS_CACHE_PATH}/testhub/testplugin/2.0.0/spec.json"
  assert_file_exist "${BEE_HUBS_CACHE_PATH}/testhub/othertestplugin/1.0.0/spec.json"
  assert_file_exist "${BEE_HUBS_CACHE_PATH}/testhub/testplugindeps/1.0.0/spec.json"
  assert_file_exist "${BEE_HUBS_CACHE_PATH}/testhub/testplugindepsdep/1.0.0/spec.json"
  assert_file_exist "${BEE_HUBS_CACHE_PATH}/testhub/testpluginmissingdep/1.0.0/spec.json"
}

@test "lists all hub urls with their plugins" {
  _setup_test_bee_hub_repo
  _setup_test_bee_hub_repo "othertesthub"
  _prepare_module
  BEE_HUBS=(
    "file://${BATS_TEST_TMPDIR}/testhub"
    "file://${BATS_TEST_TMPDIR}/othertesthub"
  )
  _strict bee::hub pull
  run _strict bee::hub ls
  assert_success

  assert_line --index 0 "file://${BATS_TEST_TMPDIR}/testhub"
  assert_line --index 1 "├── othertestplugin"
  assert_line --index 2 "├── testplugin"
  assert_line --index 3 "├── testplugindeps"
  assert_line --index 4 "├── testplugindepsdep"
  assert_line --index 5 "└── testpluginmissingdep"
  assert_line --index 6 "file://${BATS_TEST_TMPDIR}/othertesthub"
  assert_line --index 7 "├── othertestplugin"
  assert_line --index 8 "├── testplugin"
  assert_line --index 9 "├── testplugindeps"
  assert_line --index 10 "├── testplugindepsdep"
  assert_line --index 11 "└── testpluginmissingdep"
}

@test "lists specified hub urls with their plugins" {
  _setup_test_bee_hub_repo
  _setup_test_bee_hub_repo "othertesthub"
  _prepare_module
  BEE_HUBS=(
    "file://${BATS_TEST_TMPDIR}/testhub"
    "file://${BATS_TEST_TMPDIR}/othertesthub"
  )
  _strict bee::hub pull
  run _strict bee::hub ls "file://${BATS_TEST_TMPDIR}/othertesthub"
  assert_success

  assert_line --index 0 "file://${BATS_TEST_TMPDIR}/othertesthub"
  assert_line --index 1 "├── othertestplugin"
  assert_line --index 2 "├── testplugin"
  assert_line --index 3 "├── testplugindeps"
  assert_line --index 4 "├── testplugindepsdep"
  assert_line --index 5 "└── testpluginmissingdep"
}

@test "won't list hub urls when not pulled" {
  _prepare_module
  BEE_HUBS=(
    "file://${BATS_TEST_TMPDIR}/testhub"
    "file://${BATS_TEST_TMPDIR}/othertesthub"
  )
  run _strict bee::hub ls
  assert_success
  assert_line --index 0 "file://${BATS_TEST_TMPDIR}/testhub"
  assert_line --index 1 "file://${BATS_TEST_TMPDIR}/othertesthub"
}

@test "lists hub urls with their plugins and all versions" {
  _setup_test_bee_hub_repo
  _prepare_module
  # shellcheck disable=SC2034
  BEE_HUBS=(
    "file://${BATS_TEST_TMPDIR}/testhub"
  )
  _strict bee::hub pull
  run _strict bee::hub ls -a
  assert_success

  assert_line --index 0 "file://${BATS_TEST_TMPDIR}/testhub"
  assert_line --index 1 "├── othertestplugin"
  assert_line --index 2 "│    └── 1.0.0"
  assert_line --index 3 "├── testplugin"
  assert_line --index 4 "│    ├── 1.0.0"
  assert_line --index 5 "│    └── 2.0.0"
  assert_line --index 6 "├── testplugindeps"
  assert_line --index 7 "│    └── 1.0.0"
  assert_line --index 8 "├── testplugindepsdep"
  assert_line --index 9 "│    └── 1.0.0"
  assert_line --index 10 "└── testpluginmissingdep"
  assert_line --index 11 "    └── 1.0.0"
}
