setup() {
  load "test-helper.bash"
  _set_beerc
}

@test "is not executable" {
  assert_file_not_executable "${PROJECT_ROOT}/src/modules/update.bash"
}

@test "shows help when args" {
  run bee update "test"
  assert_bee_help
}

@test "reads latest version" {
  run bee update print
  assert_output "1.2.3"
  assert_file_not_exist "${BATS_TEST_TMPDIR}/caches/.bee_latest_version_cache"
}

@test "caches latest version" {
  run bee update print --cached
  assert_output "1.2.3"
  assert_file_exist "${BATS_TEST_TMPDIR}/caches/.bee_latest_version_cache"
}

@test "reads cached latest version" {
  _source_bee
  output=$(bee::run update print --cached)
  assert_output "1.2.3"

  # shellcheck disable=SC2034
  BEE_LATEST_VERSION_PATH="file://${BATS_TEST_DIRNAME}/fixtures/testversion2.txt"
  output=$(bee::run update print --cached)
  assert_output "1.2.3"
}

@test "updates cached latest version after cooldown" {
  _source_bee
  output=$(bee::run update print --cached)
  assert_output "1.2.3"

  sleep 2

  # shellcheck disable=SC2034
  BEE_LATEST_VERSION_PATH="file://${BATS_TEST_DIRNAME}/fixtures/testversion2.txt"
  output=$(bee::run update print --cached)
  assert_output "4.5.6"
}

@test "completes update with print" {
  _source_comp
  COMP_WORDS=(bee update)
  COMP_CWORD=2
  assert_comp "print"
}

@test "completes update print with --cached" {
  _source_comp
  COMP_WORDS=(bee update print)
  COMP_CWORD=3
  assert_comp "--cached"
}

@test "no comp for update print --cached" {
  _source_comp
  COMP_WORDS=(bee update --cached)
  COMP_CWORD=3
  assert_comp
}
