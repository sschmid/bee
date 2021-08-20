setup() {
  load 'test-helper.bash'
  _set_beerc
}

assert_bee_system_home() {
  assert_equal "${BEE_SYSTEM_HOME}" "${PROJECT_ROOT}"
}

@test "is executable" {
  assert_file_executable "${PROJECT_ROOT}/src/bee"
}

@test "resolves bee system home" {
  _source_bee
  assert_bee_system_home
}

@test "resolves bee system home and follows symlink" {
  ln -s "${PROJECT_ROOT}/src/bee" "${BATS_TEST_TMPDIR}/bee"
  # shellcheck disable=SC1090,SC1091
  source "${BATS_TEST_TMPDIR}/bee"
  assert_bee_system_home
}

@test "resolves bee system home and follows multiple symlinks" {
  mkdir "${BATS_TEST_TMPDIR}/src" "${BATS_TEST_TMPDIR}/bin"
  ln -s "${PROJECT_ROOT}/src/bee" "${BATS_TEST_TMPDIR}/src/bee"
  ln -s "${BATS_TEST_TMPDIR}/src/bee" "${BATS_TEST_TMPDIR}/bin/bee"
  # shellcheck disable=SC1090,SC1091
  source "${BATS_TEST_TMPDIR}/bin/bee"
  assert_bee_system_home
}

@test "sources bee-run.bash" {
  run bee
  assert_bee_help
}

@test "sources beefile" {
  _setup_beefile "echo '# test beefile sourced'"
  run bee
  assert_line --index 0 "# test beefile sourced"
}

@test "installs specified bee version" {
  _setup_beefile "BEE_VERSION=0.1.0"
  mkdir -p "${BATS_TEST_TMPDIR}/testbee/src/os"
  pushd "${BATS_TEST_TMPDIR}/testbee" > /dev/null || exit 1
    echo "echo '# test bee-run.bash 0.1.0 sourced'" > src/bee-run.bash
    cat "${PROJECT_ROOT}/src/bee-run.bash" >> src/bee-run.bash
    cp -r "${PROJECT_ROOT}/src/os" src
    git init -b main; git add . ; git commit -m "Initial commit"; git tag 0.1.0
    echo "echo '# test bee-run.bash 1.0.0 sourced'" > src/bee-run.bash
    cat "${PROJECT_ROOT}/src/bee-run.bash" >> src/bee-run.bash;
    git add . ; git commit -m "Bump version"; git tag "1.0.0"
  popd > /dev/null || exit 1
  run bee
  assert_line --index 0 "# test bee-run.bash 0.1.0 sourced"
}
