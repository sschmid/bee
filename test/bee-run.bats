setup() {
  load 'test-helper'
  _common_setup
  _export_beerc_with 'bee::secrets() { echo "bee-secrets $@"; }'
  _disable_plugin_log
}

@test "prints bee help when no args" {
  run bee
  assert_failure
  assert_bee_help
}

@test "runs args" {
  run bee echo test
  assert_success
  assert_output "test"
}

@test "runs internal bee command" {
  run bee bee::log_echo test
  assert_success
  assert_output "test"
}

@test "runs bee plugin" {
  run bee --quiet plugin_1
  assert_success
  assert_output "plugin_1 2.0.0 help"
}

@test "runs bee plugin with args" {
  run bee --quiet plugin_1 greet test
  assert_success
  cat << EOF | assert_output -
bee-secrets plugin_1 greet test
greeting test from plugin_1 2.0.0
EOF

}

@test "runs bee plugin with exact version" {
  run bee --quiet plugin_1:1.0.0
  assert_success
  assert_output "plugin_1 1.0.0 help"
}

@test "runs bee plugin with exact version with args" {
  run bee --quiet plugin_1:1.0.0 greet test
  assert_success
  cat << EOF | assert_output -
bee-secrets plugin_1 greet test
greeting test from plugin_1 1.0.0
EOF
}
