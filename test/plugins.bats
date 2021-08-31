setup() {
  load "test-helper.bash"
  _set_beerc
  BEE_CHECK_FAIL="✗" BEE_RESULT="➜"
}

@test "is not executable" {
  assert_file_not_executable "${PROJECT_ROOT}/src/modules/plugins.bash"
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
  export TEST_BEE_PLUGINS_PATHS_CUSTOM=1
  run bee plugins
  cat << 'EOF' | assert_output -
testplugin
customtestplugin
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
  assert_output --partial "${BEE_CHECK_FAIL} unknown"
}

@test "lists outdated" {
  _setup_beefile "BEE_PLUGINS=(testplugin:1.0.0 othertestplugin:1.0.0)"
  run bee plugins --outdated
  assert_output "testplugin:1.0.0 ${BEE_RESULT} testplugin:2.0.0"
}

# TODO list plugins with all dependencies (and version)
