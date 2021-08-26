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

assert_bee_help() {
  assert_output --partial "plugin-based bash automation"
}

assert_comp() {
  set +e
  _bee_completions
  set -e
  if(($#)); then
    local expected=("$@")
    local -i i n m
    n=${#COMPREPLY[@]}
    m=${#expected[@]}
    assert_equal "$n" "$m"
    for ((i = 0; i < n; i++)); do
      assert_equal "${COMPREPLY[i]}" "${expected[i]}"
    done
  else
    [ ! -v COMPREPLY ]
  fi
}

_set_beerc() { export BEE_RC="${BATS_TEST_DIRNAME}/fixtures/beerc.bash"; }
_set_beerc_fixture() { export BEE_RC="${BATS_TEST_DIRNAME}/fixtures/test-beerc.bash"; }
_set_test_modules() { export TEST_BEE_MODULES_PATH=1; }
_unset_test_modules() { unset TEST_BEE_MODULES_PATH; }

_setup_beefile() {
  echo "$@" > "${BATS_TEST_TMPDIR}/Beefile"
  export BEE_FILE="${BATS_TEST_TMPDIR}/Beefile"
}

_source_bee() {
  # shellcheck disable=SC1090,SC1091
  source "${PROJECT_ROOT}/src/bee"
}

_source_comp() {
  # shellcheck disable=SC1090,SC1091
  source "${PROJECT_ROOT}/etc/bash_completion.d/bee-completion.bash"
}

_strict() {
  set -euo pipefail
  IFS=$'\n\t'
  "$@"
}
