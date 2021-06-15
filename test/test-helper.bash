#!/usr/bin/env bash

load 'test_helper/bats-support/load.bash'
load 'test_helper/bats-assert/load.bash'
load 'test_helper/bats-file/load.bash'

export PROJECT_ROOT
PROJECT_ROOT="$(cd "${BATS_TEST_DIRNAME}/.." >/dev/null 2>&1 && pwd)"
TMP_TEST_DIR="${PROJECT_ROOT}/test/tmp"

#export BEE_HOME="${PROJECT_ROOT}"
#export BEE_RC="${PROJECT_ROOT}/test/test-beerc.sh"
#export BEE_MODULES_PATH="${PROJECT_ROOT}/modules"

#PATH="${PROJECT_ROOT}/src:${PATH}"

_source_bee(){
  source "${PROJECT_ROOT}/src/bee"
}

_setup_test_tmp_dir() {
  mkdir -p "${TMP_TEST_DIR}"
}

_teardown_test_tmp_dir() {
  rm -rf "${TMP_TEST_DIR}"
}
