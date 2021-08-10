load 'test_helper/bats-support/load.bash'
load 'test_helper/bats-assert/load.bash'
load 'test_helper/bats-file/load.bash'

PROJECT_ROOT="$(cd "${BATS_TEST_DIRNAME}/.." > /dev/null 2>&1 && pwd)"
export PROJECT_ROOT
export TMP_TEST_DIR="${PROJECT_ROOT}/test/tmp"

PATH="${PROJECT_ROOT}/src:${PATH}"

export BEE_OSTYPE="test"
# shellcheck disable=SC2034
BEE_WARN="🟠"
# shellcheck disable=SC2034
BEE_ERR="🔴"

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
  # shellcheck disable=SC1090,SC1091
  source "${PROJECT_ROOT}/src/bee"
}

_strict() {
  set -euo pipefail
  IFS=$'\n\t'
  "$@"
}

_setup_test_tmp_dir() {
  mkdir -p "${TMP_TEST_DIR}"
}

_teardown_test_tmp_dir() {
  rm -rf "${TMP_TEST_DIR}"
}

_setup_test_bee_repo() {
  mkdir "${TMP_TEST_DIR}/testbee"
  pushd "${TMP_TEST_DIR}/testbee" > /dev/null || exit 1
    mkdir -p src/os/test
    echo "echo '# test bee-run.bash 0.1.0 sourced'" > src/bee-run.bash
    cat "${PROJECT_ROOT}/src/bee-run.bash" >> src/bee-run.bash
    cp "${PROJECT_ROOT}/src/os/test.bash" "src/os/test.bash"
    git init -b main
    git add .
    git commit -m "Initial commit"
    git tag "0.1.0"
    echo "echo '# test bee-run.bash 1.0.0 sourced'" > src/bee-run.bash
    cat "${PROJECT_ROOT}/src/bee-run.bash" >> src/bee-run.bash
    git add .
    git commit -m "Bump version"
    git tag "1.0.0"
  popd > /dev/null || exit 1
}

_setup_test_bee_hub1_repo() {
  mkdir -p "${TMP_TEST_DIR}/testbeehub1/testplugin/1.0.0"
  pushd "${TMP_TEST_DIR}/testbeehub1" > /dev/null || exit 1
    echo "echo '# testplugin spec 1.0.0 sourced'" > testplugin/1.0.0/plugin.bash
    git init -b main
    git add .
    git commit -m "Initial commit"
  popd > /dev/null || exit 1
}

_setup_test_bee_hub2_repo() {
  mkdir -p "${TMP_TEST_DIR}/testbeehub2/othertestplugin/1.0.0"
  pushd "${TMP_TEST_DIR}/testbeehub2" > /dev/null || exit 1
    echo "echo '# othertestplugin spec 1.0.0 sourced'" > othertestplugin/1.0.0/plugin.bash
    git init -b main
    git add .
    git commit -m "Initial commit"
  popd > /dev/null || exit 1
}

_update_test_bee_hub1_repo() {
  mkdir -p "${TMP_TEST_DIR}/testbeehub1/testplugin/2.0.0"
  pushd "${TMP_TEST_DIR}/testbeehub1" > /dev/null || exit 1
    echo "echo '# testplugin spec 2.0.0 sourced'" > testplugin/2.0.0/plugin.bash
    git add .
    git commit -m "Initial commit"
  popd > /dev/null || exit 1
}

_setup_test_bee_hub_repo() {
  mkdir -p "${TMP_TEST_DIR}/testhub"
  cp -r "${PROJECT_ROOT}/test/fixtures/hub/" "${TMP_TEST_DIR}/testhub"
  pushd "${TMP_TEST_DIR}/testhub" > /dev/null || exit 1
    local file
    while read -r -d '' file; do
      sed -i.bak -e "s;HOME;${TMP_TEST_DIR};" -- "${file}" && rm "${file}.bak"
    done < <(find . -type f -name "spec.json" -print0)
    git init -b main
    git add .
    git commit -m "Initial commit"
  popd > /dev/null || exit 1
}

_setup_empty_bee_hub_repo() {
  mkdir -p "${TMP_TEST_DIR}/$1"
  pushd "${TMP_TEST_DIR}/$1" > /dev/null || exit 1
    echo "empty" > empty.txt
    git init -b main
    git add .
    git commit -m "Initial commit"
  popd > /dev/null || exit 1
}

_setup_testplugin_repo() {
  mkdir -p "${TMP_TEST_DIR}/plugins"
  cp -r "${PROJECT_ROOT}/test/fixtures/plugins/testplugin/1.0.0/" "${TMP_TEST_DIR}/plugins/testplugin"
  pushd "${TMP_TEST_DIR}/plugins/testplugin" > /dev/null || exit 1
    git init -b main
    git add .
    git commit -m "Initial commit"
    git tag "v1.0.0"
  popd > /dev/null || exit 1
  cp -r "${PROJECT_ROOT}/test/fixtures/plugins/testplugin/2.0.0/" "${TMP_TEST_DIR}/plugins/testplugin"
  pushd "${TMP_TEST_DIR}/plugins/testplugin" > /dev/null || exit 1
    git add .
    git commit -m "Release 2.0.0"
    git tag "v2.0.0"
  popd > /dev/null || exit 1
}

_setup_testplugindeps_repo() {
  mkdir -p "${TMP_TEST_DIR}/plugins"
  cp -r "${PROJECT_ROOT}/test/fixtures/plugins/testplugindeps/1.0.0/" "${TMP_TEST_DIR}/plugins/testplugindeps"
  pushd "${TMP_TEST_DIR}/plugins/testplugindeps" > /dev/null || exit 1
    git init -b main
    git add .
    git commit -m "Initial commit"
    git tag "v1.0.0"
  popd > /dev/null || exit 1
}
