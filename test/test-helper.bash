load 'test_helper/bats-support/load.bash'
load 'test_helper/bats-assert/load.bash'
load 'test_helper/bats-file/load.bash'

export BATS_TEST_DIRNAME
PROJECT_ROOT="$(cd "${BATS_TEST_DIRNAME}/.." > /dev/null 2>&1 && pwd)"
export PROJECT_ROOT

PATH="${PROJECT_ROOT}/src:${PATH}"

assert_bee_help() {
  assert_output --partial "plugin-based bash automation"
}

assert_comp() {
  _comp "$@"
  if(($#)); then
    assert_equal "${actual[*]}" "${expected[*]}"
  else
    refute_output
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

_strict() {
  set -euo pipefail
  IFS=$'\n\t'
  "$@"
}

# shellcheck disable=SC2207
_comp() {
  COMP_LINE="$1"
  COMP_POINT="${#COMP_LINE}"
  run _strict bee::comp
  actual=("${output}")
  actual=($(for i in "${actual[@]}"; do echo "$i"; done | sort))
  if [[ -v 2 ]]; then
    expected=("$2")
    expected=($(for i in "${expected[@]}"; do echo "$i"; done | sort))
  fi
}

_git_commit() {
  git -c commit.gpgsign=false commit "$@"
}
