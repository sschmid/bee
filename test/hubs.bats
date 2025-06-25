setup() {
  load 'test-helper'
  _common_setup
  _export_beerc
}

@test "lists all hub urls with their plugins" {
  _create_bee_hub_repo "${TEST_HUB_1}"
  _create_bee_hub_repo "${TEST_HUB_2}"
  bee pull
  run bee hubs
  assert_success

  cat << EOF | assert_output -
file://${BATS_TEST_TMPDIR}/${TEST_HUB_1}
├── plugin_1
├── plugin_2
├── plugin_with_deps
├── plugin_with_deps_on_deps
├── plugin_with_missing_deps
└── plugin_with_wrong_hash

file://${BATS_TEST_TMPDIR}/${TEST_HUB_2}
├── plugin_1
├── plugin_2
├── plugin_with_deps
├── plugin_with_deps_on_deps
├── plugin_with_missing_deps
└── plugin_with_wrong_hash
EOF
}

@test "lists specified hub urls with their plugins" {
  _create_bee_hub_repo "${TEST_HUB_1}"
  _create_bee_hub_repo "${TEST_HUB_2}"
  bee pull
  run bee hubs "file://${BATS_TEST_TMPDIR}/${TEST_HUB_2}"
  assert_success

  cat << EOF | assert_output -
file://${BATS_TEST_TMPDIR}/${TEST_HUB_2}
├── plugin_1
├── plugin_2
├── plugin_with_deps
├── plugin_with_deps_on_deps
├── plugin_with_missing_deps
└── plugin_with_wrong_hash
EOF
}

@test "won't list hub urls when not pulled" {
  run bee hubs
  assert_success
  cat << EOF | assert_output -
file://${BATS_TEST_TMPDIR}/${TEST_HUB_1}
file://${BATS_TEST_TMPDIR}/${TEST_HUB_2}
EOF
}

@test "lists hub urls as list" {
  _create_bee_hub_repo "${TEST_HUB_1}"
  _create_bee_hub_repo "${TEST_HUB_2}"
  bee pull
  run bee hubs --list
  assert_success
  cat << EOF | assert_output -
plugin_1
plugin_2
plugin_with_deps
plugin_with_deps_on_deps
plugin_with_missing_deps
plugin_with_wrong_hash
plugin_1
plugin_2
plugin_with_deps
plugin_with_deps_on_deps
plugin_with_missing_deps
plugin_with_wrong_hash
EOF
}

@test "lists hub urls with their plugins and all versions" {
  _create_bee_hub_repo "${TEST_HUB_1}"
  _create_bee_hub_repo "${TEST_HUB_2}"
  bee pull
  run bee hubs --all
  assert_success

  cat << EOF | assert_output -
file://${BATS_TEST_TMPDIR}/${TEST_HUB_1}
├── plugin_1
│    ├── 0.2.0
│    ├── 1.0.0
│    └── 2.0.0
├── plugin_2
│    └── 1.0.0
├── plugin_with_deps
│    └── 1.0.0
├── plugin_with_deps_on_deps
│    └── 1.0.0
├── plugin_with_missing_deps
│    └── 1.0.0
└── plugin_with_wrong_hash
    └── 1.0.0

file://${BATS_TEST_TMPDIR}/${TEST_HUB_2}
├── plugin_1
│    ├── 0.2.0
│    ├── 1.0.0
│    └── 2.0.0
├── plugin_2
│    └── 1.0.0
├── plugin_with_deps
│    └── 1.0.0
├── plugin_with_deps_on_deps
│    └── 1.0.0
├── plugin_with_missing_deps
│    └── 1.0.0
└── plugin_with_wrong_hash
    └── 1.0.0

EOF
}

@test "completes bee hubs with options and hub urls" {
  local expected=(--all --list "file://${BATS_TEST_TMPDIR}/${TEST_HUB_1}" "file://${BATS_TEST_TMPDIR}/${TEST_HUB_2}")
  assert_comp "bee hubs " "${expected[*]}"
}

@test "completes bee hubs with multiple hub urls" {
  local expected=("file://${BATS_TEST_TMPDIR}/${TEST_HUB_1}" "file://${BATS_TEST_TMPDIR}/${TEST_HUB_2}")
  assert_comp "bee hubs myurl " "${expected[*]}"
}

@test "completes bee hubs --list with hub urls" {
  local expected=("file://${BATS_TEST_TMPDIR}/${TEST_HUB_1}" "file://${BATS_TEST_TMPDIR}/${TEST_HUB_2}")
  assert_comp "bee hubs --list " "${expected[*]}"
}

@test "completes bee hubs --list with multiple hub urls" {
  local expected=("file://${BATS_TEST_TMPDIR}/${TEST_HUB_1}" "file://${BATS_TEST_TMPDIR}/${TEST_HUB_2}")
  assert_comp "bee hubs --list myurl " "${expected[*]}"
}
