setup() {
  load "test-helper.bash"
  _set_beerc
  MODULE_PATH="${PROJECT_ROOT}/src/modules/new.bash"
  _source_bee
  # shellcheck disable=SC1090
  source "${MODULE_PATH}"
}

@test "is not executable" {
  assert_file_not_executable "${MODULE_PATH}"
}

@test "creates Beefile" {
  run _strict bee::new "${BATS_TEST_TMPDIR}/Beefile"
  assert_success
  assert_output "Created ${BATS_TEST_TMPDIR}/Beefile"
  assert_file_exist "${BATS_TEST_TMPDIR}/Beefile"
}

@test "doesn't create Beefile if already exists" {
  run _strict bee::new "${BATS_TEST_TMPDIR}/Beefile"
  run _strict bee::new "${BATS_TEST_TMPDIR}/Beefile"
  assert_failure
  assert_output "${BEE_ERR} ${BATS_TEST_TMPDIR}/Beefile already exists"
}

@test "sets default vars" {
  run _strict bee::new "${BATS_TEST_TMPDIR}/Beefile"
  run cat "${BATS_TEST_TMPDIR}/Beefile"
  cat << EOF | assert_output --partial -
BEE_PROJECT=$(basename "${PWD}")
BEE_VERSION=$(bee::run --version)
BEE_RESOURCES=.bee
EOF
}
