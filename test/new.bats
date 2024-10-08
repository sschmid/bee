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
  cd "${BATS_TEST_TMPDIR}"
  mkdir test
  run bee new "test/Beefile"
  assert_success
  assert_output "Created test/Beefile"
  assert_file_exist "${BATS_TEST_TMPDIR}/test/Beefile"
}

@test "doesn't create Beefile if already exists" {
  cd "${BATS_TEST_TMPDIR}"
  mkdir test
  run bee new "test/Beefile"
  run bee new "test/Beefile"
  assert_failure
  assert_output "${BEE_ERROR} test/Beefile already exists"
}

@test "sets default vars" {
  run bee new "${BATS_TEST_TMPDIR}/Beefile"
  assert_success
  run cat "${BATS_TEST_TMPDIR}/Beefile"
  cat << EOF | assert_output --partial -
BEE_PROJECT="$(basename "${PWD}")"
BEE_VERSION=$(cat "${PROJECT_ROOT}/version.txt")
EOF
}
