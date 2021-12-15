setup() {
  load "test-helper.bash"
  _unset_beefile
}

@test "creates Beefile in folder" {
  cd "${BATS_TEST_TMPDIR}"
  run bee new
  assert_success
  assert_output "Created Beefile"
  assert_file_exist "${BATS_TEST_TMPDIR}/Beefile"
}

@test "creates custom Beefile" {
  run bee new "${BATS_TEST_TMPDIR}/Beefile"
  assert_success
  assert_output "Created ${BATS_TEST_TMPDIR}/Beefile"
  assert_file_exist "${BATS_TEST_TMPDIR}/Beefile"
}

@test "doesn't create Beefile if already exists" {
  run bee new "${BATS_TEST_TMPDIR}/Beefile"
  run bee new "${BATS_TEST_TMPDIR}/Beefile"
  assert_failure
  assert_output "${BEE_ERR} ${BATS_TEST_TMPDIR}/Beefile already exists"
}

@test "sets default vars" {
  run bee new "${BATS_TEST_TMPDIR}/Beefile"
  assert_success
  run cat "${BATS_TEST_TMPDIR}/Beefile"
  cat << EOF | assert_output --partial -
BEE_PROJECT=$(basename "${PWD}")
BEE_VERSION=$(cat "${PROJECT_ROOT}/version.txt")
EOF
}
