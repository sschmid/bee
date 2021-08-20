setup() {
  load "test-helper.bash"
  _set_beerc
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
  assert_line --index 0 "testplugin"
  assert_line --index 1 "customtestplugin"
}

@test "lists nothing when no beefile" {
  run bee plugins
  assert_success
  refute_output
}

@test "lists unknown plugins as missing" {
  _setup_beefile "BEE_PLUGINS=(unknown)"
  run bee plugins
  assert_success
  assert_output --partial "✗ unknown"
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
  assert_output --partial "✗ unknown"
}

@test "lists outdated" {
  _setup_beefile "BEE_PLUGINS=(testplugin:1.0.0 othertestplugin:1.0.0)"
  run bee plugins -o
  assert_line --index 0 "testplugin:1.0.0 ➜ testplugin:2.0.0"
  assert_line --index 1 "othertestplugin:1.0.0"
}

# list plugins with all dependencies (and version)
