setup() {
  load "test-helper.bash"
  cd "${BATS_TEST_TMPDIR}" || exit
}

@test "no prompt when no Beefile" {
  _unset_beefile
  run bee prompt
  assert_failure
  refute_output
}

@test "prints bee version" {
  # shellcheck disable=SC2016
  _set_beerc_with 'BEE_LATEST_VERSION_PATH="file://${PROJECT_ROOT}/version.txt"'
  _setup_beefile
  run bee prompt
  assert_success
  assert_output "${BEE_ICON} $(cat "${PROJECT_ROOT}/version.txt")"
}

@test "mark with asterisk when newer version is available" {
  # shellcheck disable=SC2016
  _set_beerc_with 'BEE_LATEST_VERSION_PATH="file://${BATS_TEST_DIRNAME}/fixtures/testversion2.txt"'
  run bee prompt
  assert_success
  assert_output "${BEE_ICON} $(cat "${PROJECT_ROOT}/version.txt")*"
}
