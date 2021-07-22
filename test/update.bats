setup() {
  load "test-helper.bash"
  _set_beerc
}

teardown() {
  _teardown_test_tmp_dir
}

@test "is not executable" {
  assert_file_not_executable "${PROJECT_ROOT}/src/modules/update.bash"
}

@test "shows help when args" {
  run bee update "test"
  assert_output --partial "plugin-based bash automation"
}

# This test would actually pull and update the system bee
#@test "doesn't update specified bee version" {
#  _set_test_beefile
#  _setup_test_tmp_dir
#  _setup_test_bee_repo
#  bee update
#  run bee
#  assert_line --index 0 "# test bee-run.bash 0.1.0 sourced"
#}

@test "reads latest version" {
  run bee update --read-latest-version
  assert_output "1.2.3"
  assert_file_not_exist "${TMP_TEST_DIR}/caches/.bee_latest_version_cache"
}

@test "caches latest version" {
  run bee update --read-latest-version-cached
  assert_output "1.2.3"
  assert_file_exist "${TMP_TEST_DIR}/caches/.bee_latest_version_cache"
}

@test "reads cached latest version" {
  _source_bee
  output=$(bee::run update --read-latest-version-cached)
  assert_output "1.2.3"

  # shellcheck disable=SC2034
  BEE_LATEST_VERSION_PATH="file://${PROJECT_ROOT}/test/testversion2.txt"
  output=$(bee::run update --read-latest-version-cached)
  assert_output "1.2.3"
}

@test "updates cached latest version after cooldown" {
  _source_bee
  output=$(bee::run update --read-latest-version-cached)
  assert_output "1.2.3"

  sleep 2

  # shellcheck disable=SC2034
  BEE_LATEST_VERSION_PATH="file://${PROJECT_ROOT}/test/testversion2.txt"
  output=$(bee::run update --read-latest-version-cached)
  assert_output "4.5.6"
}
