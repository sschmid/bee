# shellcheck disable=SC2154
setup() {
  load 'test-helper'
  _common_setup
}

assert_hash() {
  run --separate-stderr bee hash "$1"
  assert_success
  assert_equal "${output}" "$2"
  assert_equal "${stderr}" "$1
$3
$2  -"
}

@test "shows help when no args" {
  run bee hash
  assert_failure
  assert_bee_help
}

@test "hashes files in folder" {
  mkdir -p "${BATS_TEST_TMPDIR}/test"
  echo "test 1" >"${BATS_TEST_TMPDIR}/test/file 1"
  echo "test 2" >"${BATS_TEST_TMPDIR}/test/file 2"
  echo "test 3" >"${BATS_TEST_TMPDIR}/test/file 3"

  assert_hash "${BATS_TEST_TMPDIR}/test" "31bcb3fe3b26a09a4f8deab60dd8a995b7f0cabaa50681aa87d7d0586975fc25" \
"3cd203ac11340842055a6de561c9d69ca4493e912bd4c3c440c80711e16d5aee  ./file 1
ef691f74bb2e7cb7e9b48b4d57e9e62fa535a0a6ea0100676c4fc492cca8b6d0  ./file 2
f332dc0b25c681863f10100f0fedd2b2e6ddcc9abe360d6d780d73b7322c9aa5  ./file 3"
}

@test "includes file names in hash" {
  # file content is the same as in previous test, but file names are different
  mkdir -p "${BATS_TEST_TMPDIR}/test"
  echo "test 1" >"${BATS_TEST_TMPDIR}/test/file 1 X"
  echo "test 2" >"${BATS_TEST_TMPDIR}/test/file 2 X"
  echo "test 3" >"${BATS_TEST_TMPDIR}/test/file 3 X"

  assert_hash "${BATS_TEST_TMPDIR}/test" "b157413796c74b113cd051f71cb079105ed92411d2b22ba571ba9acf3be08661" \
"3cd203ac11340842055a6de561c9d69ca4493e912bd4c3c440c80711e16d5aee  ./file 1 X
ef691f74bb2e7cb7e9b48b4d57e9e62fa535a0a6ea0100676c4fc492cca8b6d0  ./file 2 X
f332dc0b25c681863f10100f0fedd2b2e6ddcc9abe360d6d780d73b7322c9aa5  ./file 3 X"
}

@test "ignores .git and .DS_Store by default" {
  mkdir -p "${BATS_TEST_TMPDIR}/test/.git"
  touch "${BATS_TEST_TMPDIR}/test/.git/ignore"
  touch "${BATS_TEST_TMPDIR}/test/.DS_Store"
  echo "test 1" >"${BATS_TEST_TMPDIR}/test/file 1"
  echo "test 2" >"${BATS_TEST_TMPDIR}/test/file 2"

  assert_hash "${BATS_TEST_TMPDIR}/test" "3e3fc366c4186b90bbe40ad754d158ed27d5a0a94a207bc83ec0ad5b7a10f427" \
"3cd203ac11340842055a6de561c9d69ca4493e912bd4c3c440c80711e16d5aee  ./file 1
ef691f74bb2e7cb7e9b48b4d57e9e62fa535a0a6ea0100676c4fc492cca8b6d0  ./file 2"
}

@test "ignores additional custom patterns" {
  mkdir -p "${BATS_TEST_TMPDIR}/test/.git"
  touch "${BATS_TEST_TMPDIR}/test/.git/ignore" "${BATS_TEST_TMPDIR}/test/.DS_Store"
  echo "test 1" >"${BATS_TEST_TMPDIR}/test/file 1"
  echo "test 2" >"${BATS_TEST_TMPDIR}/test/file 2"
  echo "test 3" >"${BATS_TEST_TMPDIR}/test/file 3"
  export BEE_HUB_HASH_EXCLUDE="file 1,file 2"

  assert_hash "${BATS_TEST_TMPDIR}/test" "9d245100fd93f0b9e5dde8b380feb70996fbc63e2f508f570db9f70a6deeac65" \
"f332dc0b25c681863f10100f0fedd2b2e6ddcc9abe360d6d780d73b7322c9aa5  ./file 3"
}

@test "hashes plugin folder" {
  assert_hash "${BATS_TEST_DIRNAME}/fixtures/plugins/plugin_1/2.0.0" "ab4b5200a5c2308db63a4306d335d41afe6d447fa2c11150a163fd01c833c3d4" \
"3a427a45a5dd0b6ae06b4dd1937bb357971ffe18ccbfc81f0c49eb55ae27458e  ./LICENSE.txt
948ff7047eec3890a4dc593e153b8cf383bc817ca007a8c2b3a0ac832240f3bf  ./plugin_1.bash
e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855  ./res/.gitkeep
c28fcca53637bc88e124af1725df13cb98c69dedefd62fb3cdbe1cdb6b760624  ./version.txt"
}
