#!/usr/bin/env bash

_common_test_setup() {
  load 'test_helper/bats-support/load.bash'
  load 'test_helper/bats-assert/load.bash'
  load 'test_helper/bats-file/load.bash'
  export PROJECT_ROOT
  PROJECT_ROOT="$(cd "$(dirname "${BATS_TEST_FILENAME}")/.." >/dev/null 2>&1 && pwd)"
  TMP_DIR="${PROJECT_ROOT}/test/tmp"
  PATH="${PROJECT_ROOT}/src:${PATH}"
}

_create_test_tmp_dir() {
  mkdir -p "${TMP_DIR}"
}

_delete_test_tmp_dir() {
  rm -rf "${TMP_DIR}"
}
