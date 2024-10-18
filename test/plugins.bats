setup() {
  load "test-helper.bash"
  _set_beerc
  _source_beerc
}

@test "shows help when args" {
  run bee plugins test
  assert_failure
  assert_bee_help
}

@test "lists enabled plugins without version" {
  _setup_beefile "BEE_PLUGINS=(testplugin testplugindeps)"
  run bee plugins
  assert_success
  cat << 'EOF' | assert_output -
testplugin
testplugindeps
EOF

  _setup_beefile "BEE_PLUGINS=(testplugin:1.0.0 testplugindeps:1.0.0)"
  run bee plugins
  assert_success
  cat << 'EOF' | assert_output -
testplugin
testplugindeps
EOF
}

@test "lists enabled plugins from all plugin paths" {
  _setup_beefile "BEE_PLUGINS=(testplugin customtestplugin)"
  # shellcheck disable=SC2030,SC2031
  export TEST_BEE_PLUGINS_PATHS_CUSTOM=1
  run bee plugins
  assert_success
  cat << 'EOF' | assert_output -
customtestplugin
testplugin
EOF
}

@test "lists local plugins" {
  _setup_beefile "BEE_PLUGINS=(localplugin)"
  # shellcheck disable=SC2030,SC2031
  export TEST_BEE_PLUGINS_PATHS_CUSTOM=1
  run bee plugins
  assert_success
  assert_output "localplugin"
}

@test "lists nothing when no Beefile" {
  run bee plugins
  assert_success
  refute_output
}

@test "lists all unknown plugins as missing" {
  _setup_beefile "BEE_PLUGINS=(unknown2 unknown1)"
  run bee plugins
  assert_failure
  cat << EOF | assert_output -
#E${BEE_CHECK_FAIL} unknown1#
#E${BEE_CHECK_FAIL} unknown2#
EOF
}

@test "lists enabled plugins with version" {
  _setup_beefile "BEE_PLUGINS=(testplugin testplugindeps)"
  run bee plugins --version
  assert_success
  cat << 'EOF' | assert_output -
testplugin:1.0.0
testplugindeps:1.0.0
EOF

  _setup_beefile "BEE_PLUGINS=(testplugin:1.0.0 testplugindeps:1.0.0)"
  run bee plugins --version
  assert_success
  cat << 'EOF' | assert_output -
testplugin:1.0.0
testplugindeps:1.0.0
EOF
}

@test "lists local plugins with version" {
  _setup_beefile "BEE_PLUGINS=(localplugin)"
  # shellcheck disable=SC2030,SC2031
  export TEST_BEE_PLUGINS_PATHS_CUSTOM=1
  run bee plugins --version
  assert_success
  cat << 'EOF' | assert_output -
localplugin:local
EOF
}

@test "lists all unknown plugins with version as missing" {
  _setup_beefile "BEE_PLUGINS=(unknown1:9.0.0 unknown2:9.0.0)"
  run bee plugins --version
  assert_failure
  cat << EOF | assert_output -
#E${BEE_CHECK_FAIL} unknown1:9.0.0#
#E${BEE_CHECK_FAIL} unknown2:9.0.0#
EOF
}

@test "lists all plugins from all plugin paths" {
  _setup_beefile "BEE_PLUGINS=(unknown)"
  # shellcheck disable=SC2030,SC2031
  export TEST_BEE_PLUGINS_PATHS_CUSTOM=1
  run bee plugins --all
  assert_line "#E${BEE_CHECK_FAIL} unknown#"
  assert_line "othertestplugin"
  assert_line "testplugin"
  assert_line "testplugindeps"
  assert_line "testplugindepsdep"
  assert_line "testpluginmissingdep"
  assert_line "customtestplugin"
}

@test "lists outdated" {
  _setup_beefile "BEE_PLUGINS=(testplugin:1.0.0 othertestplugin:1.0.0)"
  run bee plugins --outdated
  assert_success
  assert_output "testplugin:1.0.0 ${BEE_RESULT} testplugin:2.0.0"
}

@test "compares lock file against installed plugins and fails when missing plugins" {
  cat << 'EOF' > "${BEE_FILE}.lock"
├── unknown2:9.0.0
├── testplugin:1.0.0
└── unknown1:9.0.0
EOF

  run bee plugins --lock
  assert_failure
  cat << EOF | assert_output -
#E${BEE_CHECK_FAIL} unknown1:9.0.0#
#E${BEE_CHECK_FAIL} unknown2:9.0.0#
EOF
}

@test "compares lock file against installed plugins" {
  cat << 'EOF' > "${BEE_FILE}.lock"
├── testplugin:2.0.0
└── testplugin:1.0.0
EOF

  run bee plugins --lock
  assert_success
  refute_output
}

@test "compares against lock file only if it exists" {
  run bee plugins --lock
  assert_failure
  refute_output
}

# TODO list plugins with all dependencies (and version)

@test "completes bee plugins with options" {
  local expected=(--all --lock --outdated --version)
  assert_comp "bee plugins " "${expected[*]}"
}

@test "completes bee plugins with multiple options and removes already used ones" {
  local expected
  expected=(--lock --outdated --version)
  assert_comp "bee plugins --all " "${expected[*]}"

  expected=(--all --outdated --version)
  assert_comp "bee plugins --lock " "${expected[*]}"

  expected=(--all --lock --version)
  assert_comp "bee plugins --outdated " "${expected[*]}"

  expected=(--all --lock --outdated)
  assert_comp "bee plugins --version " "${expected[*]}"
}
