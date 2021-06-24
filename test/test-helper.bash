load 'test_helper/bats-support/load.bash'
load 'test_helper/bats-assert/load.bash'
load 'test_helper/bats-file/load.bash'

export PROJECT_ROOT
PROJECT_ROOT="$(cd "${BATS_TEST_DIRNAME}/.." > /dev/null 2>&1 && pwd)"
export TMP_TEST_DIR="${PROJECT_ROOT}/test/tmp"

PATH="${PROJECT_ROOT}/src:${PATH}"

_set_beerc() {
  export BEE_RC="${BATS_TEST_DIRNAME}/beerc.bash"
}

_set_test_beerc() {
  export BEE_RC="${BATS_TEST_DIRNAME}/test-beerc.bash"
}

_set_test_fixture_beerc() {
  export BEE_RC="${BATS_TEST_DIRNAME}/fixtures/test-beerc.bash"
}

_set_test_beefile() {
  export BEE_FILE="${BATS_TEST_DIRNAME}/test-beefile.bash"
}

_set_test_fixture_beefile() {
  export BEE_FILE="${BATS_TEST_DIRNAME}/fixtures/test-beefile.bash"
}

_source_bee() {
  source "${PROJECT_ROOT}/src/bee"
}

_setup_test_tmp_dir() {
  mkdir -p "${TMP_TEST_DIR}"
}

_teardown_test_tmp_dir() {
  rm -rf "${TMP_TEST_DIR}"
}

_setup_test_bee_repo() {
  mkdir "${TMP_TEST_DIR}/testbee"
  pushd "${TMP_TEST_DIR}/testbee" > /dev/null
    mkdir src
    echo "echo '# test bee-run.bash 0.1.0 sourced'" > src/bee-run.bash
    git init -b main
    git add .
    git commit -m "Initial commit"
    git tag "0.1.0"
    echo "echo '# test bee-run.bash 1.0.0 sourced'" > src/bee-run.bash
    git add .
    git commit -m "Bump version"
    git tag "1.0.0"
  popd > /dev/null
}
