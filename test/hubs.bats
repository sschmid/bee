setup() {
  load "test-helper.bash"
  load "test-helper-hub.bash"
  _set_beerc
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

@test "lists hub urls as list" {
  _setup_test_bee_hub_repo
  _setup_test_bee_hub_repo "othertesthub"
  bee pull
  run bee hubs --list
  assert_success
  cat << EOF | assert_output -
othertestplugin
testplugin
testplugindeps
testplugindepsdep
testpluginmissingdep
othertestplugin
testplugin
testplugindeps
testplugindepsdep
testpluginmissingdep
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

@test "completes bee hubs with options and hub urls" {
  local expected=(--all --list "file://${BATS_TEST_TMPDIR}/testhub" "file://${BATS_TEST_TMPDIR}/othertesthub")
  assert_comp "bee hubs " "${expected[*]}"
}

@test "completes bee hubs with multiple hub urls" {
  local expected=("file://${BATS_TEST_TMPDIR}/testhub" "file://${BATS_TEST_TMPDIR}/othertesthub")
  assert_comp "bee hubs myurl " "${expected[*]}"
}

@test "completes bee hubs --list with hub urls" {
  local expected=("file://${BATS_TEST_TMPDIR}/testhub" "file://${BATS_TEST_TMPDIR}/othertesthub")
  assert_comp "bee hubs --list " "${expected[*]}"
}

@test "completes bee hubs --list with multiple hub urls" {
  local expected=("file://${BATS_TEST_TMPDIR}/testhub" "file://${BATS_TEST_TMPDIR}/othertesthub")
  assert_comp "bee hubs --list myurl " "${expected[*]}"
}
