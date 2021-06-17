#!/usr/bin/env bash

load 'test_helper/bats-support/load.bash'
load 'test_helper/bats-assert/load.bash'
load 'test_helper/bats-file/load.bash'

export PROJECT_ROOT
PROJECT_ROOT="$(cd "${BATS_TEST_DIRNAME}/.." >/dev/null 2>&1 && pwd)"
TMP_TEST_DIR="${PROJECT_ROOT}/test/tmp"

export BEE_RC="${BATS_TEST_DIRNAME}/beerc.sh"

PATH="${PROJECT_ROOT}/src:${PATH}"

_source_bee(){
  source "${PROJECT_ROOT}/src/bee"
}

_set_test_beerc() {
  BEE_RC="${BATS_TEST_DIRNAME}/fixtures/test-beerc.sh"
}

_setup_test_tmp_dir() {
  mkdir -p "${TMP_TEST_DIR}"
}

_teardown_test_tmp_dir() {
  rm -rf "${TMP_TEST_DIR}"
}
