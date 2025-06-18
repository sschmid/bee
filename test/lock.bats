setup() {
  load 'test-helper'
  _common_setup
  _export_beerc
}

@test "doesn't create lock file when no Beefile " {
  _unset_beefile
  cd "${BATS_TEST_TMPDIR}"
  _create_bee_hub_repo "${TEST_HUB_1}"
  _create_plugin_repo
  bee pull
  run bee install
  assert_output "No Beefile"
  run find "${BATS_TEST_TMPDIR}" -name "*.lock"
  refute_output
}

@test "creates Beefile.lock " {
  _create_bee_hub_repo "${TEST_HUB_1}"
  _create_plugin_repo
  _create_beefile_with 'BEE_PLUGINS=(plugin_1)'
  bee pull
  run bee install
  cat << EOF | assert_output -
Installing plugins based on ${BATS_TEST_TMPDIR}/Beefile
└── #S${BEE_CHECK_SUCCESS} plugin_1:2.0.0 (file://${BATS_TEST_TMPDIR}/${TEST_HUB_1})#
EOF
  assert_file_exist "${BATS_TEST_TMPDIR}/Beefile.lock"
}

@test "creates custom lock file" {
  _create_bee_hub_repo "${TEST_HUB_1}"
  _create_plugin_repo
  echo 'BEE_PLUGINS=(plugin_1)' >"${BATS_TEST_TMPDIR}/test"
  export BEE_FILE="${BATS_TEST_TMPDIR}/test"
  bee pull
  run bee install
  cat << EOF | assert_output -
Installing plugins based on ${BATS_TEST_TMPDIR}/test
└── #S${BEE_CHECK_SUCCESS} plugin_1:2.0.0 (file://${BATS_TEST_TMPDIR}/${TEST_HUB_1})#
EOF
  assert_file_exist "${BATS_TEST_TMPDIR}/test.lock"
}

@test "writes plugins with version to lock file" {
  _create_bee_hub_repo "${TEST_HUB_1}"
  _create_plugin_repo
  _create_generic_plugin_repo plugin_2
  _create_generic_plugin_repo plugin_with_deps
  _create_generic_plugin_repo plugin_with_deps_on_deps
  _create_beefile_with 'BEE_PLUGINS=(plugin_with_deps_on_deps plugin_with_deps)'
  bee pull
  run bee install
  run cat "${BATS_TEST_TMPDIR}/Beefile.lock"
  cat << EOF | assert_output -
├── plugin_with_deps_on_deps:1.0.0
│   ├── plugin_with_deps:1.0.0
│   │   ├── plugin_1:1.0.0
│   │   └── plugin_2:1.0.0
│   └── plugin_1:1.0.0
└── plugin_with_deps:1.0.0
    ├── plugin_1:1.0.0
    └── plugin_2:1.0.0
EOF
}

@test "writes local plugins to lock file" {
  _create_bee_hub_repo "${TEST_HUB_1}"
  _create_plugin_repo
  _create_generic_plugin_repo plugin_2
  _create_beefile_with 'BEE_PLUGINS=(local_plugin)'
  # shellcheck disable=SC2030,SC2031
  export TEST_BEE_PLUGINS_PATHS_CUSTOM=1
  bee pull
  run bee install
  run cat "${BATS_TEST_TMPDIR}/Beefile.lock"
  cat << EOF | assert_output -
└── local_plugin:local
    ├── plugin_1:1.0.0
    └── plugin_2:1.0.0
EOF
}

@test "writes explicit local plugins to lock file" {
  _create_bee_hub_repo "${TEST_HUB_1}"
  _create_plugin_repo
  _create_generic_plugin_repo plugin_2
  _create_beefile_with 'BEE_PLUGINS=(local_plugin:local)'
  # shellcheck disable=SC2030,SC2031
  export TEST_BEE_PLUGINS_PATHS_CUSTOM=1
  bee pull
  run bee install
  run cat "${BATS_TEST_TMPDIR}/Beefile.lock"
  cat << EOF | assert_output -
└── local_plugin:local
    ├── plugin_1:1.0.0
    └── plugin_2:1.0.0
EOF
}

@test "doesn't create lock file when installing manually " {
  _create_bee_hub_repo "${TEST_HUB_1}"
  _create_plugin_repo
  _create_beefile_with
  bee pull
  bee install plugin_1
  run find "${BATS_TEST_TMPDIR}" -name "*.lock"
  refute_output
}

@test "installs plugins from lock file" {
  _create_bee_hub_repo "${TEST_HUB_1}"
  _create_plugin_repo
  _create_generic_plugin_repo plugin_2
  _create_generic_plugin_repo plugin_with_deps
  _create_generic_plugin_repo plugin_with_deps_on_deps
  _create_beefile_with
  cat << 'EOF' >"${BATS_TEST_TMPDIR}/Beefile.lock"
├── plugin_with_deps_on_deps:1.0.0
│   ├── plugin_with_deps:1.0.0
│   │   ├── plugin_1:1.0.0
│   │   └── plugin_2:1.0.0
│   └── plugin_1:1.0.0
└── plugin_with_deps:1.0.0
    ├── plugin_1:1.0.0
    └── plugin_2:1.0.0
EOF
  bee pull
  run bee install
  cat << EOF | assert_output -
Installing plugins based on ${BATS_TEST_TMPDIR}/Beefile.lock
├── #S${BEE_CHECK_SUCCESS} plugin_with_deps_on_deps:1.0.0 (file://${BATS_TEST_TMPDIR}/${TEST_HUB_1})#
│   ├── #S${BEE_CHECK_SUCCESS} plugin_with_deps:1.0.0 (file://${BATS_TEST_TMPDIR}/${TEST_HUB_1})#
│   │   ├── #S${BEE_CHECK_SUCCESS} plugin_1:1.0.0 (file://${BATS_TEST_TMPDIR}/${TEST_HUB_1})#
│   │   └── #S${BEE_CHECK_SUCCESS} plugin_2:1.0.0 (file://${BATS_TEST_TMPDIR}/${TEST_HUB_1})#
│   └── plugin_1:1.0.0 (file://${BATS_TEST_TMPDIR}/${TEST_HUB_1})
└── plugin_with_deps:1.0.0 (file://${BATS_TEST_TMPDIR}/${TEST_HUB_1})
    ├── plugin_1:1.0.0 (file://${BATS_TEST_TMPDIR}/${TEST_HUB_1})
    └── plugin_2:1.0.0 (file://${BATS_TEST_TMPDIR}/${TEST_HUB_1})
EOF
}

@test "skips local plugins from lock file" {
  _create_bee_hub_repo "${TEST_HUB_1}"
  _create_plugin_repo
  _create_generic_plugin_repo plugin_2
  _create_beefile_with
  # shellcheck disable=SC2030,SC2031
  export TEST_BEE_PLUGINS_PATHS_CUSTOM=1
  export TEST_PLUGIN_QUIET=1
  cat << 'EOF' >"${BATS_TEST_TMPDIR}/Beefile.lock"
└── local_plugin:local
    ├── plugin_1:1.0.0
    └── plugin_2:1.0.0
EOF
  bee pull
  run bee install
  cat << EOF | assert_output -
Installing plugins based on ${BATS_TEST_TMPDIR}/Beefile.lock
└── local_plugin:local (${BATS_TEST_DIRNAME}/fixtures/custom_plugins/local_plugin/local_plugin.bash)
    ├── #S${BEE_CHECK_SUCCESS} plugin_1:1.0.0 (file://${BATS_TEST_TMPDIR}/${TEST_HUB_1})#
    └── #S${BEE_CHECK_SUCCESS} plugin_2:1.0.0 (file://${BATS_TEST_TMPDIR}/${TEST_HUB_1})#
EOF
}

@test "doesn't modify lock file when installing" {
  _create_bee_hub_repo "${TEST_HUB_1}"
  _create_plugin_repo
  _create_generic_plugin_repo plugin_2
  _create_generic_plugin_repo plugin_with_deps
  _create_generic_plugin_repo plugin_with_deps_on_deps
  _create_beefile_with
  cat << 'EOF' >"${BATS_TEST_TMPDIR}/Beefile.lock"
├── plugin_with_deps_on_deps:1.0.0
│   ├── plugin_with_deps:1.0.0
│   │   ├── plugin_1:1.0.0
│   │   └── plugin_2:1.0.0
│   └── plugin_1:1.0.0
└── plugin_with_deps:1.0.0
    ├── plugin_1:1.0.0
    └── plugin_2:1.0.0
EOF
  bee pull
  bee install
  run cat "${BATS_TEST_TMPDIR}/Beefile.lock"
  cat << EOF | assert_output -
├── plugin_with_deps_on_deps:1.0.0
│   ├── plugin_with_deps:1.0.0
│   │   ├── plugin_1:1.0.0
│   │   └── plugin_2:1.0.0
│   └── plugin_1:1.0.0
└── plugin_with_deps:1.0.0
    ├── plugin_1:1.0.0
    └── plugin_2:1.0.0
EOF
}
