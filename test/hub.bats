setup() {
  load "test-helper.bash"
  load "test-helper-hub.bash"
  _set_beerc
  _source_beerc
  BEE_HUBS_CACHE_PATH="${BEE_CACHES_PATH}/hubs"
}

_setup_mock_bee_hub_repo() {
  local hub="$1" plugin="$2"
  mkdir -p "${BATS_TEST_TMPDIR}/${hub}/${plugin}/1.0.0"
  pushd "${BATS_TEST_TMPDIR}/${hub}" > /dev/null || exit 1
    touch "${plugin}/1.0.0/plugin.json"
    git init -b main; git add . ; _git_commit -m "Initial commit"
  popd > /dev/null || exit 1
}

_update_mock_bee_hub_repo() {
  local hub="$1" plugin="$2" version="$3"
  mkdir -p "${BATS_TEST_TMPDIR}/${hub}/${plugin}/${version}"
  pushd "${BATS_TEST_TMPDIR}/${hub}" > /dev/null || exit 1
    touch "${plugin}/${version}/plugin.json"; git add . ; _git_commit -m "Release ${version}"
  popd > /dev/null || exit 1
}

@test "file:// to cache path" {
  # shellcheck disable=SC2016
  run bee bee::hub::to_cache_path 'file://${HOME}/bee/beehub'
  assert_success
  assert_output "beehub"
}

@test "https:// to cache path" {
  run bee bee::hub::to_cache_path "https://github.com/sschmid/beehub.git"
  assert_success
  assert_output "github.com/sschmid/beehub"
}

@test "git:// to cache path" {
  run bee bee::hub::to_cache_path "git://github.com/sschmid/beehub"
  assert_success
  assert_output "github.com/sschmid/beehub"
}

@test "git@ to cache path" {
  run bee bee::hub::to_cache_path "git@github.com:sschmid/beehub.git"
  assert_success
  assert_output "github.com/sschmid/beehub"
}

@test "ssh:// to cache path" {
  run bee bee::hub::to_cache_path "ssh://git@github.com/sschmid/beehub"
  assert_success
  assert_output "github.com/sschmid/beehub"
}

@test "warns when unsupported url" {
  run bee bee::hub::to_cache_path "unknown"
  assert_success
  assert_output "${BEE_WARN} Unsupported hub url: unknown"
}

@test "clones all registered hubs" {
  _setup_mock_bee_hub_repo testhub testplugin
  _setup_mock_bee_hub_repo othertesthub othertestplugin
  run bee pull
  assert_success
  assert_file_exist "${BEE_HUBS_CACHE_PATH}/testhub/testplugin/1.0.0/plugin.json"
  assert_file_exist "${BEE_HUBS_CACHE_PATH}/othertesthub/othertestplugin/1.0.0/plugin.json"
}

@test "clones specified hubs" {
  _setup_mock_bee_hub_repo testhub testplugin
  _setup_mock_bee_hub_repo othertesthub othertestplugin
  run bee pull "file://${BATS_TEST_TMPDIR}/testhub"
  assert_success
  assert_file_exist "${BEE_HUBS_CACHE_PATH}/testhub/testplugin/1.0.0/plugin.json"
  assert_dir_not_exist "${BEE_HUBS_CACHE_PATH}/othertesthub"
}

@test "ignores cloning unknown hubs" {
  _setup_mock_bee_hub_repo testhub testplugin
  _setup_mock_bee_hub_repo othertesthub othertestplugin
  # shellcheck disable=SC2016
  _set_beerc_with 'BEE_HUBS=("file://${BATS_TEST_TMPDIR}/testhub" "unknown" "file://${BATS_TEST_TMPDIR}/othertesthub")'
  run bee pull
  assert_success
  assert_output --partial "${BEE_WARN} Unsupported hub url: unknown"
  assert_file_exist "${BEE_HUBS_CACHE_PATH}/testhub/testplugin/1.0.0/plugin.json"
  assert_dir_not_exist "${BEE_HUBS_CACHE_PATH}/unknown"
  assert_file_exist "${BEE_HUBS_CACHE_PATH}/othertesthub/othertestplugin/1.0.0/plugin.json"
}

@test "pulls existing hubs" {
  _setup_mock_bee_hub_repo testhub testplugin
  _set_beerc_with 'BEE_HUB_PULL_COOLDOWN=-1'
  bee pull
  assert_file_not_exist "${BEE_HUBS_CACHE_PATH}/testhub/testplugin/2.0.0/plugin.json"

  _update_mock_bee_hub_repo testhub testplugin 2.0.0
  run bee pull
  assert_success
  assert_file_exist "${BEE_HUBS_CACHE_PATH}/testhub/testplugin/2.0.0/plugin.json"
}

@test "pulls test hub" {
  _setup_test_bee_hub_repo
  # shellcheck disable=SC2016
  _set_beerc_with 'BEE_HUBS=("file://${BATS_TEST_TMPDIR}/testhub")'
  run bee pull
  assert_file_exist "${BEE_HUBS_CACHE_PATH}/testhub/testplugin/1.0.0/plugin.json"
  assert_file_exist "${BEE_HUBS_CACHE_PATH}/testhub/testplugin/2.0.0/plugin.json"
  assert_file_exist "${BEE_HUBS_CACHE_PATH}/testhub/othertestplugin/1.0.0/plugin.json"
  assert_file_exist "${BEE_HUBS_CACHE_PATH}/testhub/testplugindeps/1.0.0/plugin.json"
  assert_file_exist "${BEE_HUBS_CACHE_PATH}/testhub/testplugindepsdep/1.0.0/plugin.json"
  assert_file_exist "${BEE_HUBS_CACHE_PATH}/testhub/testpluginmissingdep/1.0.0/plugin.json"
}

@test "pull sets ts" {
  _setup_mock_bee_hub_repo testhub testplugin
  run bee pull "file://${BATS_TEST_TMPDIR}/testhub"
  assert_success
  assert_file_exist "${BEE_HUBS_CACHE_PATH}/.ts"
}

@test "skips pull when within cooldown period" {
  _setup_mock_bee_hub_repo testhub testplugin
  _setup_mock_bee_hub_repo othertesthub othertestplugin
  _set_beerc_with 'BEE_HUB_PULL_COOLDOWN=1'
  bee pull "file://${BATS_TEST_TMPDIR}/testhub"

  run bee pull "file://${BATS_TEST_TMPDIR}/othertesthub"
  assert_success
  assert_file_exist "${BEE_HUBS_CACHE_PATH}/testhub/testplugin/1.0.0/plugin.json"
  assert_file_not_exist "${BEE_HUBS_CACHE_PATH}/othertesthub/othertestplugin/1.0.0/plugin.json"

  sleep 3
  run bee pull "file://${BATS_TEST_TMPDIR}/othertesthub"
  assert_file_exist "${BEE_HUBS_CACHE_PATH}/othertesthub/othertestplugin/1.0.0/plugin.json"
}

@test "forces pull even when within cooldown period" {
  _setup_mock_bee_hub_repo testhub testplugin
  _setup_mock_bee_hub_repo othertesthub othertestplugin
  _source_bee
  _set_beerc_with 'BEE_HUB_PULL_COOLDOWN=999'

  run bee pull "file://${BATS_TEST_TMPDIR}/testhub"
  assert_success
  assert_file_exist "${BEE_HUBS_CACHE_PATH}/testhub/testplugin/1.0.0/plugin.json"
  assert_dir_not_exist "${BEE_HUBS_CACHE_PATH}/othertesthub"

  run bee pull --force
  assert_success
  assert_file_exist "${BEE_HUBS_CACHE_PATH}/othertesthub/othertestplugin/1.0.0/plugin.json"
}

@test "lists all hub urls with their plugins" {
  _setup_test_bee_hub_repo
  _setup_test_bee_hub_repo "othertesthub"
  bee pull
  run bee hubs
  assert_success

  cat << EOF | assert_output -
file://${BATS_TEST_TMPDIR}/testhub
├── othertestplugin
├── testplugin
├── testplugindeps
├── testplugindepsdep
└── testpluginmissingdep

file://${BATS_TEST_TMPDIR}/othertesthub
├── othertestplugin
├── testplugin
├── testplugindeps
├── testplugindepsdep
└── testpluginmissingdep
EOF
}

@test "lists specified hub urls with their plugins" {
  _setup_test_bee_hub_repo
  _setup_test_bee_hub_repo "othertesthub"
  bee pull
  run bee hubs "file://${BATS_TEST_TMPDIR}/othertesthub"
  assert_success

  cat << EOF | assert_output -
file://${BATS_TEST_TMPDIR}/othertesthub
├── othertestplugin
├── testplugin
├── testplugindeps
├── testplugindepsdep
└── testpluginmissingdep
EOF
}

@test "won't list hub urls when not pulled" {
  run bee hubs
  assert_success
  cat << EOF | assert_output -
file://${BATS_TEST_TMPDIR}/testhub
file://${BATS_TEST_TMPDIR}/othertesthub
EOF
}

@test "lists hub urls with their plugins and all versions" {
  _setup_test_bee_hub_repo
  _setup_test_bee_hub_repo "othertesthub"
  bee pull
  run bee hubs --all
  assert_success

  cat << EOF | assert_output -
file://${BATS_TEST_TMPDIR}/testhub
├── othertestplugin
│    └── 1.0.0
├── testplugin
│    ├── 0.1.0
│    ├── 0.2.0
│    ├── 1.0.0
│    └── 2.0.0
├── testplugindeps
│    └── 1.0.0
├── testplugindepsdep
│    └── 1.0.0
└── testpluginmissingdep
    └── 1.0.0

file://${BATS_TEST_TMPDIR}/othertesthub
├── othertestplugin
│    └── 1.0.0
├── testplugin
│    ├── 0.1.0
│    ├── 0.2.0
│    ├── 1.0.0
│    └── 2.0.0
├── testplugindeps
│    └── 1.0.0
├── testplugindepsdep
│    └── 1.0.0
└── testpluginmissingdep
    └── 1.0.0
EOF
}

@test "prints plugin info" {
  _setup_test_bee_hub_repo
  bee pull
  run bee info testplugin:1.0.0
  assert_success
  assert_output --partial '"name": "testplugin"'
  assert_output --partial '"version": "1.0.0"'
}

@test "prints plugin info when parsing error" {
  _setup_test_bee_hub_repo
  bee pull
  run bee info testplugin:0.2.0
  assert_success
  assert_output --partial '"name": "testplugin"'
  assert_output --partial '"version": "0.2.0"'
  assert_output --partial 'FORMAT-ERROR'
}

#@test "completes hub with ls plugins pull info install hash lint" {
#  _source_bee
#  local expected=("ls" "plugins" "pull" "info" "install" "hash" "lint")
#  assert_comp "bee hub " "${expected[*]}"
#}

#@test "completes hub ls with options and hub urls" {
#  _source_bee
#  local expected=("-a" "--all" "file://${BATS_TEST_TMPDIR}/testhub" "file://${BATS_TEST_TMPDIR}/othertesthub")
#  assert_comp "bee hub ls " "${expected[*]}"
#}
#
#@test "completes hub ls with multiple hub urls" {
#  _source_bee
#  local expected=("file://${BATS_TEST_TMPDIR}/testhub" "file://${BATS_TEST_TMPDIR}/othertesthub")
#  assert_comp "bee hub ls myurl " "${expected[*]}"
#}
#
#@test "completes hub pull with options and hub urls" {
#  _source_bee
#  local expected=("-f" "--force" "file://${BATS_TEST_TMPDIR}/testhub" "file://${BATS_TEST_TMPDIR}/othertesthub")
#  assert_comp "bee hub pull " "${expected[*]}"
#}
#
#@test "completes hub pull with multiple hub urls" {
#  _source_bee
#  local expected=("file://${BATS_TEST_TMPDIR}/testhub" "file://${BATS_TEST_TMPDIR}/othertesthub")
#  assert_comp "bee hub pull myurl " "${expected[*]}"
#}
#
#@test "completes hub info with plugin" {
#  _setup_test_bee_hub_repo
#  _setup_test_bee_hub_repo "othertesthub"
#  _source_bee
#  _strict bee::hub pull
#  local expected=("othertestplugin" "testplugin" "testplugindeps" "testplugindepsdep" "testpluginmissingdep")
#  assert_comp "bee hub info " "${expected[*]}"
#}
#
#@test "completes hub install with options and plugins" {
#  _setup_test_bee_hub_repo
#  _setup_test_bee_hub_repo "othertesthub"
#  _source_bee
#  _strict bee::hub pull
#  local expected=("-f" "--force" "othertestplugin" "testplugin" "testplugindeps" "testplugindepsdep" "testpluginmissingdep")
#  assert_comp "bee hub install " "${expected[*]}"
#}
#
#@test "completes hub install multiple with plugins" {
#  _setup_test_bee_hub_repo
#  _setup_test_bee_hub_repo "othertesthub"
#  _source_bee
#  _strict bee::hub pull
#  local expected=("othertestplugin" "testplugin" "testplugindeps" "testplugindepsdep" "testpluginmissingdep")
#  assert_comp "bee hub install myplugin " "${expected[*]}"
#}
#
#@test "completes hub plugins with hub urls" {
#  _source_bee
#  local expected=("file://${BATS_TEST_TMPDIR}/testhub" "file://${BATS_TEST_TMPDIR}/othertesthub")
#  assert_comp "bee hub plugins " "${expected[*]}"
#}
#
#@test "completes hub plugins with multiple hub urls" {
#  _source_bee
#  local expected=("file://${BATS_TEST_TMPDIR}/testhub" "file://${BATS_TEST_TMPDIR}/othertesthub")
#  assert_comp "bee hub plugins myurl " "${expected[*]}"
#}
