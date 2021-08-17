load 'test_helper/bats-support/load.bash'
load 'test_helper/bats-assert/load.bash'
load 'test_helper/bats-file/load.bash'

export BATS_TEST_DIRNAME
PROJECT_ROOT="$(cd "${BATS_TEST_DIRNAME}/.." > /dev/null 2>&1 && pwd)"
export PROJECT_ROOT

PATH="${PROJECT_ROOT}/src:${PATH}"

# shellcheck disable=SC2034
BEE_WARN="🟠"
# shellcheck disable=SC2034
BEE_ERR="🔴"

_set_beerc() { export BEE_RC="${BATS_TEST_DIRNAME}/beerc.bash"; }
_set_beerc_fixture() { export BEE_RC="${BATS_TEST_DIRNAME}/fixtures/test-beerc.bash"; }
_set_test_modules() { export TEST_BEE_MODULES_PATH=1; }
_unset_test_modules() { unset TEST_BEE_MODULES_PATH; }
_set_beefile() { export BEE_FILE="${BATS_TEST_DIRNAME}/test-beefile.bash"; }
_set_beefile_fixture() { export BEE_FILE="${BATS_TEST_DIRNAME}/fixtures/test-beefile.bash"; }

_source_bee() {
  # shellcheck disable=SC1090,SC1091
  source "${PROJECT_ROOT}/src/bee"
}

_strict() {
  set -euo pipefail
  IFS=$'\n\t'
  "$@"
}

_setup_test_bee_repo() {
  mkdir "${BATS_TEST_TMPDIR}/testbee"
  pushd "${BATS_TEST_TMPDIR}/testbee" > /dev/null || exit 1
    mkdir -p src/os
    echo "echo '# test bee-run.bash 0.1.0 sourced'" > src/bee-run.bash
    cat "${PROJECT_ROOT}/src/bee-run.bash" >> src/bee-run.bash
    cp -r "${PROJECT_ROOT}/src/os" src
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
  mkdir -p "${BATS_TEST_TMPDIR}/testbeehub1/testplugin/1.0.0"
  pushd "${BATS_TEST_TMPDIR}/testbeehub1" > /dev/null || exit 1
    echo "echo '# testplugin spec 1.0.0 sourced'" > testplugin/1.0.0/plugin.bash
    git init -b main
    git add .
    git commit -m "Initial commit"
  popd > /dev/null || exit 1
}

_setup_test_bee_hub2_repo() {
  mkdir -p "${BATS_TEST_TMPDIR}/testbeehub2/othertestplugin/1.0.0"
  pushd "${BATS_TEST_TMPDIR}/testbeehub2" > /dev/null || exit 1
    echo "echo '# othertestplugin spec 1.0.0 sourced'" > othertestplugin/1.0.0/plugin.bash
    git init -b main
    git add .
    git commit -m "Initial commit"
  popd > /dev/null || exit 1
}

_update_test_bee_hub1_repo() {
  mkdir -p "${BATS_TEST_TMPDIR}/testbeehub1/testplugin/2.0.0"
  pushd "${BATS_TEST_TMPDIR}/testbeehub1" > /dev/null || exit 1
    echo "echo '# testplugin spec 2.0.0 sourced'" > testplugin/2.0.0/plugin.bash
    git add .
    git commit -m "Initial commit"
  popd > /dev/null || exit 1
}

_setup_test_bee_hub_repo() {
  local name="${1:-"testhub"}"
  mkdir -p "${BATS_TEST_TMPDIR}/${name}"
  cp -r "${BATS_TEST_DIRNAME}/fixtures/hub/." "${BATS_TEST_TMPDIR}/${name}"
  pushd "${BATS_TEST_TMPDIR}/${name}" > /dev/null || exit 1
    local file
    while read -r -d '' file; do
      sed -i.bak -e "s;HOME;${BATS_TEST_TMPDIR};" -- "${file}" && rm "${file}.bak"
    done < <(find . -type f -name "spec.json" -print0)
    git init -b main
    git add .
    git commit -m "Initial commit"
  popd > /dev/null || exit 1
}

_setup_empty_bee_hub_repo() {
  mkdir -p "${BATS_TEST_TMPDIR}/$1"
  pushd "${BATS_TEST_TMPDIR}/$1" > /dev/null || exit 1
    echo "empty" > empty.txt
    git init -b main
    git add .
    git commit -m "Initial commit"
  popd > /dev/null || exit 1
}

_setup_testplugin_repo() {
  _setup_generic_plugin_repo testplugin
  cp -r "${BATS_TEST_DIRNAME}/fixtures/plugins/testplugin/2.0.0/." "${BATS_TEST_TMPDIR}/plugins/testplugin"
  pushd "${BATS_TEST_TMPDIR}/plugins/testplugin" > /dev/null || exit 1
    git add .
    git commit -m "Release 2.0.0"
    git tag "v2.0.0"
  popd > /dev/null || exit 1
}

_setup_generic_plugin_repo() {
  mkdir -p "${BATS_TEST_TMPDIR}/plugins"
  cp -r "${BATS_TEST_DIRNAME}/fixtures/plugins/$1/1.0.0/." "${BATS_TEST_TMPDIR}/plugins/$1"
  pushd "${BATS_TEST_TMPDIR}/plugins/$1" > /dev/null || exit 1
    git init -b main
    git add .
    git commit -m "Initial commit"
    git tag "v1.0.0"
  popd > /dev/null || exit 1
}
