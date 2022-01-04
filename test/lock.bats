setup() {
  load "test-helper.bash"
  load "test-helper-hub.bash"
  _set_beerc
}

@test "doesn't create lock file when no Beefile " {
  _unset_beefile
  cd "${BATS_TEST_TMPDIR}"
  _setup_test_bee_hub_repo
  _setup_testplugin_repo
  bee pull
  run bee install
  assert_output "No Beefile"
  run find "${BATS_TEST_TMPDIR}" -name "*.lock"
  refute_output
}

@test "creates Beefile.lock " {
  _setup_test_bee_hub_repo
  _setup_testplugin_repo
  _setup_beefile 'BEE_PLUGINS=(testplugin)'
  bee pull
  run bee install
  cat << EOF | assert_output -
Installing plugins based on ${BATS_TEST_TMPDIR}/Beefile
└── #S${BEE_CHECK_SUCCESS} testplugin:2.0.0 (file://${BATS_TEST_TMPDIR}/testhub)#
EOF
  assert_file_exist "${BATS_TEST_TMPDIR}/Beefile.lock"
}

@test "creates custom lock file" {
  _setup_test_bee_hub_repo
  _setup_testplugin_repo
  echo 'BEE_PLUGINS=(testplugin)' > "${BATS_TEST_TMPDIR}/test"
  export BEE_FILE="${BATS_TEST_TMPDIR}/test"
  bee pull
  run bee install
  cat << EOF | assert_output -
Installing plugins based on ${BATS_TEST_TMPDIR}/test
└── #S${BEE_CHECK_SUCCESS} testplugin:2.0.0 (file://${BATS_TEST_TMPDIR}/testhub)#
EOF
  assert_file_exist "${BATS_TEST_TMPDIR}/test.lock"
}

@test "writes plugins with version to lock file" {
  _setup_test_bee_hub_repo
  _setup_testplugin_repo
  _setup_generic_plugin_repo othertestplugin
  _setup_generic_plugin_repo testplugindeps
  _setup_generic_plugin_repo testplugindepsdep
  _setup_beefile 'BEE_PLUGINS=(testplugindepsdep testplugindeps)'
  bee pull
  run bee install
  run cat "${BATS_TEST_TMPDIR}/Beefile.lock"
  cat << EOF | assert_output -
├── testplugindepsdep:1.0.0
│   ├── testplugindeps:1.0.0
│   │   ├── testplugin:1.0.0
│   │   └── othertestplugin:1.0.0
│   └── testplugin:1.0.0
└── testplugindeps:1.0.0
    ├── testplugin:1.0.0
    └── othertestplugin:1.0.0
EOF
}

@test "doesn't create lock file when installing manually " {
  _setup_test_bee_hub_repo
  _setup_testplugin_repo
  _setup_beefile
  bee pull
  bee install testplugin
  run find "${BATS_TEST_TMPDIR}" -name "*.lock"
  refute_output
}

@test "installs plugins from lock file" {
  _setup_test_bee_hub_repo
  _setup_testplugin_repo
  _setup_generic_plugin_repo othertestplugin
  _setup_generic_plugin_repo testplugindeps
  _setup_generic_plugin_repo testplugindepsdep
  _setup_beefile
  cat << 'EOF' > "${BATS_TEST_TMPDIR}/Beefile.lock"
├── testplugindepsdep:1.0.0
│   ├── testplugindeps:1.0.0
│   │   ├── testplugin:1.0.0
│   │   └── othertestplugin:1.0.0
│   └── testplugin:1.0.0
└── testplugindeps:1.0.0
    ├── testplugin:1.0.0
    └── othertestplugin:1.0.0
EOF
  bee pull
  run bee install
  cat << EOF | assert_output -
Installing plugins based on ${BATS_TEST_TMPDIR}/Beefile.lock
├── #S${BEE_CHECK_SUCCESS} testplugindepsdep:1.0.0 (file://${BATS_TEST_TMPDIR}/testhub)#
│   ├── #S${BEE_CHECK_SUCCESS} testplugindeps:1.0.0 (file://${BATS_TEST_TMPDIR}/testhub)#
│   │   ├── #S${BEE_CHECK_SUCCESS} testplugin:1.0.0 (file://${BATS_TEST_TMPDIR}/testhub)#
│   │   └── #S${BEE_CHECK_SUCCESS} othertestplugin:1.0.0 (file://${BATS_TEST_TMPDIR}/testhub)#
│   └── testplugin:1.0.0 (file://${BATS_TEST_TMPDIR}/testhub)
├── testplugindeps:1.0.0 (file://${BATS_TEST_TMPDIR}/testhub)
│   ├── testplugin:1.0.0 (file://${BATS_TEST_TMPDIR}/testhub)
│   └── othertestplugin:1.0.0 (file://${BATS_TEST_TMPDIR}/testhub)
├── testplugin:1.0.0 (file://${BATS_TEST_TMPDIR}/testhub)
└── othertestplugin:1.0.0 (file://${BATS_TEST_TMPDIR}/testhub)
EOF
}

@test "doesn't modify lock file when installing" {
  _setup_test_bee_hub_repo
  _setup_testplugin_repo
  _setup_generic_plugin_repo othertestplugin
  _setup_generic_plugin_repo testplugindeps
  _setup_generic_plugin_repo testplugindepsdep
  _setup_beefile
  cat << 'EOF' > "${BATS_TEST_TMPDIR}/Beefile.lock"
├── testplugindepsdep:1.0.0
│   ├── testplugindeps:1.0.0
│   │   ├── testplugin:1.0.0
│   │   └── othertestplugin:1.0.0
│   └── testplugin:1.0.0
└── testplugindeps:1.0.0
    ├── testplugin:1.0.0
    └── othertestplugin:1.0.0
EOF
  bee pull
  bee install
  run cat "${BATS_TEST_TMPDIR}/Beefile.lock"
  cat << EOF | assert_output -
├── testplugindepsdep:1.0.0
│   ├── testplugindeps:1.0.0
│   │   ├── testplugin:1.0.0
│   │   └── othertestplugin:1.0.0
│   └── testplugin:1.0.0
└── testplugindeps:1.0.0
    ├── testplugin:1.0.0
    └── othertestplugin:1.0.0
EOF
}
