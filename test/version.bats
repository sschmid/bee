setup() {
  load "test-helper.bash"
  _set_beerc
}

@test "shows help when args" {
  run bee version test
  assert_bee_help
}

@test "prints version" {
  run bee version
  assert_success
  assert_output "$(cat "${PROJECT_ROOT}/version.txt")"
}

@test "reads latest version" {
  run bee version --latest
  assert_output "1.2.3"
  assert_file_not_exist "${BATS_TEST_TMPDIR}/cache/.bee_latest_version_cache"
}

@test "caches latest version" {
  run bee version --latest --cached
  assert_output "1.2.3"
  assert_file_exist "${BATS_TEST_TMPDIR}/cache/.bee_latest_version_cache"
}

@test "reads cached latest version" {
  run bee version --latest --cached
  assert_output "1.2.3"

  # shellcheck disable=SC2016
  _set_beerc_with 'BEE_LATEST_VERSION_PATH="file://${BATS_TEST_DIRNAME}/fixtures/testversion2.txt"'
  run bee version --latest --cached
  assert_output "1.2.3"
}

@test "updates cached latest version after cooldown" {
  run bee version --latest --cached
  assert_output "1.2.3"

  sleep 5

  # shellcheck disable=SC2016
  _set_beerc_with 'BEE_LATEST_VERSION_PATH="file://${BATS_TEST_DIRNAME}/fixtures/testversion2.txt"'
  run bee version --latest --cached
  assert_output "99.99.99"
}

@test "completes bee version with --latest" {
  assert_comp "bee version " "--latest"
}

@test "completes bee version --latest with --cached" {
  assert_comp "bee version --latest " "--cached"
}
