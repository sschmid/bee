setup() {
  load 'test-helper'
  _common_setup
  _export_beerc
}

assert_bee_system_home() {
  assert_equal "${BEE_SYSTEM_HOME}" "${PROJECT_ROOT}"
}

@test "resolves bee system home" {
  # shellcheck disable=SC1090,SC1091
  source "${PROJECT_ROOT}/src/bee"
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

@test "sources bee-main.bash" {
  run bee
  assert_failure
  assert_bee_help
}

@test "sources BEE_FILE when specified" {
  _create_beefile_with "echo '# test Beefile sourced'"
  run bee :
  assert_success
  assert_output "# test Beefile sourced"
}

@test "sets and sources Beefile in working dir" {
  _unset_beefile
  cd "${BATS_TEST_TMPDIR}"
  echo "echo '# test Beefile sourced'" >"Beefile"
  run bee env BEE_FILE
  assert_success
  cat << 'EOF' | assert_output -
# test Beefile sourced
Beefile
EOF
}

@test "has default BEE_RESOURCES" {
  run bee env BEE_RESOURCES
  assert_success
  assert_output ".bee"
}

@test "can overwrite BEE_RESOURCES in Beefile" {
  _create_beefile_with "BEE_RESOURCES=test"
  run bee env BEE_RESOURCES
  assert_success
  assert_output "test"
}

@test "installs specified bee version" {
  _create_beefile_with "BEE_VERSION=1.0.0"
  mkdir -p "${BATS_TEST_TMPDIR}/testbee/src/os"
  pushd "${BATS_TEST_TMPDIR}/testbee" >/dev/null || exit 1
    echo "echo '# test bee-main.bash 1.0.0 sourced'" >src/bee-main.bash
    cat "${PROJECT_ROOT}/src/bee-main.bash" >>src/bee-main.bash
    cp -r "${PROJECT_ROOT}/src/os" src
    git init
    git add .
    _git_commit -m "Initial commit"
    git tag 1.0.0
    echo "echo '# test bee-main.bash 1.1.0 sourced'" >src/bee-main.bash
    cat "${PROJECT_ROOT}/src/bee-main.bash" >>src/bee-main.bash;
    git add .
    _git_commit -m "Bump version"
    git tag "1.1.0"
  popd >/dev/null || exit 1
  run bee :
  assert_output "# test bee-main.bash 1.0.0 sourced"
}

@test "applies bee 0.x migration" {
  _create_beefile_with "BEE_VERSION=0.41.0"
  mkdir -p "${BATS_TEST_TMPDIR}/testbee/src"
  pushd "${BATS_TEST_TMPDIR}/testbee" >/dev/null || exit 1
    echo "echo '# test bee 0.41.0 sourced'" >src/bee
    chmod +x src/bee
    git init
    git add .
    _git_commit -m "Initial commit"
    git tag 0.41.0
  popd >/dev/null || exit 1
  run bee :
  assert_output "# test bee 0.41.0 sourced"
}

@test "completes bee with commands" {
  _export_beerc_with 'BEE_PLUGINS_PATHS=(unknown)'
  assert_comp "bee " "${ALL_BEE_OPTIONS[*]} ${ALL_BEE_COMMANDS[*]}"
}

@test "completes bee options with commands and removes already used options" {
  _export_beerc_with 'BEE_PLUGINS_PATHS=(unknown)'
  assert_comp "bee --quiet --verbose " "--batch --help ${ALL_BEE_COMMANDS[*]}"
}

@test "no completion for bee --help" {
  _export_beerc_with 'BEE_PLUGINS_PATHS=(unknown)'
  assert_comp "bee --help "
}

@test "completes with plugins and custom plugins" {
  export TEST_BEE_PLUGINS_PATHS_CUSTOM=1
  assert_comp "bee " "${ALL_BEE_OPTIONS[*]} ${ALL_BEE_COMMANDS[*]} ${ALL_TEST_PLUGINS[*]} ${ALL_CUSTOM_PLUGINS[*]} testplugindepslatest"
}

@test "completes available functions" {
  _export_beerc_with 'BEE_PLUGINS_PATHS=(unknown)'
  _create_beefile_with "test::func() { :; }"
  assert_comp "bee " "test::func ${ALL_BEE_OPTIONS[*]} ${ALL_BEE_COMMANDS[*]}"
}
