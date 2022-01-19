setup() {
  load "test-helper.bash"
}

@test "shows help when no args" {
  run bee hash
  assert_bee_help
}

@test "ignores .git and .DS_Store by default" {
  mkdir -p "${BATS_TEST_TMPDIR}/test/.git"
  touch "${BATS_TEST_TMPDIR}/test/.git/ignore" "${BATS_TEST_TMPDIR}/test/.DS_Store"
  echo "test1" > "${BATS_TEST_TMPDIR}/test/file1"
  echo "test2" > "${BATS_TEST_TMPDIR}/test/file2"

  run bee hash "${BATS_TEST_TMPDIR}/test"
  assert_success
  cat << EOF | assert_output -
${BATS_TEST_TMPDIR}/test
634b027b1b69e1242d40d53e312b3b4ac7710f55be81f289b549446ef6778bee  ./file1
7d6fd7774f0d87624da6dcf16d0d3d104c3191e771fbe2f39c86aed4b2bf1a0f  ./file2
a27685987e1e8bb3b81f9de9299ae1c93872680be504f28627ea7b5ef33eeeea  -
EOF
}

@test "ignores custom patterns" {
  mkdir -p "${BATS_TEST_TMPDIR}/test/.git"
  touch "${BATS_TEST_TMPDIR}/test/.DS_Store" "${BATS_TEST_TMPDIR}/test/.git/ignore"
  echo "test1" > "${BATS_TEST_TMPDIR}/test/file1"
  echo "test2" > "${BATS_TEST_TMPDIR}/test/file2"
  echo "test3" > "${BATS_TEST_TMPDIR}/test/file3"
  export BEE_HUB_HASH_EXCLUDE="file1 file2"

  run bee hash "${BATS_TEST_TMPDIR}/test"
  assert_success
  cat << EOF | assert_output -
${BATS_TEST_TMPDIR}/test
ab03c34f1ece08211fe2a8039fd6424199b3f5d7b55ff13b1134b364776c45c5  ./file3
1f51d29e27f42e9f42b32cbbb5e09208c7a8d2fd0410cb9609b17e3be793137f  -
EOF
}

@test "hashes plugin folder" {
  run bee hash "${BATS_TEST_DIRNAME}/fixtures/plugins/testplugin/2.0.0"
  assert_success
  cat << EOF | assert_output -
${BATS_TEST_DIRNAME}/fixtures/plugins/testplugin/2.0.0
3a427a45a5dd0b6ae06b4dd1937bb357971ffe18ccbfc81f0c49eb55ae27458e  ./LICENSE.txt
e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855  ./res/.gitkeep
9a96c9a87803ad80b39407dffeec4ef0359a3c339b92f6c42b01d203db1d703a  ./testplugin.bash
c28fcca53637bc88e124af1725df13cb98c69dedefd62fb3cdbe1cdb6b760624  ./version.txt
5ebab3a1c8be86a86145ecb7edcfa567e4c0a24066953e321debd8ea23ffd472  -
EOF
}
