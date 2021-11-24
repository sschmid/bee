setup() {
  load "test-helper.bash"
  _set_beerc
  BEE_CHECK_FAIL="✗" BEE_RESULT="➜"
}

@test "lists enabled plugins" {
  _setup_beefile "BEE_PLUGINS=(testplugin)"
  run bee plugins
  assert_success
  assert_output "testplugin"

  _setup_beefile "BEE_PLUGINS=(testplugin:1.0.0)"
  run bee plugins
  assert_success
  assert_output "testplugin"
}

@test "lists enabled plugins from all plugin paths" {
  _setup_beefile "BEE_PLUGINS=(testplugin customtestplugin)"
  # shellcheck disable=SC2030
  export TEST_BEE_PLUGINS_PATHS_CUSTOM=1
  run bee plugins
  cat << 'EOF' | assert_output -
customtestplugin
testplugin
EOF
 }

@test "lists nothing when no Beefile" {
  run bee plugins
  assert_success
  refute_output
}

@test "lists unknown plugins as missing" {
  _setup_beefile "BEE_PLUGINS=(unknown)"
  run bee plugins
  assert_success
  assert_output --partial "${BEE_CHECK_FAIL} unknown"
}

@test "lists enabled plugins with version" {
  _setup_beefile "BEE_PLUGINS=(testplugin)"
  run bee plugins -v
  assert_output "testplugin:2.0.0"

  _setup_beefile "BEE_PLUGINS=(testplugin:1.0.0)"
  run bee plugins -v
  assert_output "testplugin:1.0.0"
}

@test "lists unknown plugins with version as missing" {
  _setup_beefile "BEE_PLUGINS=(unknown:9.0.0)"
  run bee plugins -v
  assert_success
  assert_output --partial "${BEE_CHECK_FAIL} unknown:9.0.0"
}

@test "lists all plugins from all plugin paths" {
  _setup_beefile "BEE_PLUGINS=(unknown)"
  # shellcheck disable=SC2031
  export TEST_BEE_PLUGINS_PATHS_CUSTOM=1
  run bee plugins -a

  assert_line --partial "${BEE_CHECK_FAIL} unknown"
  assert_line "othertestplugin"
  assert_line "testplugin"
  assert_line "testplugindeps"
  assert_line "testplugindepsdep"
  assert_line "testpluginmissingdep"
  assert_line "customtestplugin"

  run bee plugins --all
  assert_line --partial "${BEE_CHECK_FAIL} unknown"
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
  assert_output "testplugin:1.0.0 ${BEE_RESULT} testplugin:2.0.0"
}

# TODO list plugins with all dependencies (and version)

@test "completes plugins with options" {
  _source_bee
  local expected=(
    "--all" "-a"
    "--outdated" "-o"
    "--version" "-v"
  )
  assert_comp "bee plugins " "${expected[*]}"
}

@test "completes plugins with multiple options and removes already used ones" {
  _source_bee
  local expected=(
    "--outdated" "-o"
    "--version" "-v"
  )
  assert_comp "bee plugins -a " "${expected[*]}"
}
