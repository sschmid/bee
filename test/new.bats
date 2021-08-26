setup() {
  load "test-helper.bash"
  _set_beerc
}

@test "is not executable" {
  assert_file_not_executable "${PROJECT_ROOT}/src/modules/new.bash"
}

@test "creates Beefile" {
  skip "enable test mode in new-bash first"
  run bee new "${BATS_TEST_TMPDIR}/Beefile"
  assert_success
  assert_output "Created ${BATS_TEST_TMPDIR}/Beefile"
  assert_file_exist "${BATS_TEST_TMPDIR}/Beefile"
}

@test "doesn't create Beefile if already exists" {
  skip "enable test mode in new-bash first"
  bee new "${BATS_TEST_TMPDIR}/Beefile"
  run bee new "${BATS_TEST_TMPDIR}/Beefile"
  assert_failure
  assert_output "${BEE_ERR} ${BATS_TEST_TMPDIR}/Beefile already exists"
}

@test "sets default vars" {
  skip "enable test mode in new-bash first"
  bee new "${BATS_TEST_TMPDIR}/Beefile"
  run cat "${BATS_TEST_TMPDIR}/Beefile"
  assert_line --index 0 "BEE_PROJECT=$(basename "${PWD}") "
  assert_line --index 1 "BEE_VERSION=$(bee --version)"
  assert_line --index 2 "BEE_RESOURCES=.bee"
}
