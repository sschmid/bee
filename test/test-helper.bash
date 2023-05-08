load 'test_helper/bats-support/load.bash'
load 'test_helper/bats-assert/load.bash'
load 'test_helper/bats-file/load.bash'

bats_require_minimum_version 1.5.0

export BATS_TEST_DIRNAME
PROJECT_ROOT="$(cd "${BATS_TEST_DIRNAME}/.." > /dev/null 2>&1 && pwd)"
export PROJECT_ROOT

PATH="${PROJECT_ROOT}/src:${PATH}"

export BEE_COLOR_SUCCESS="#S"
export BEE_COLOR_WARN="#W"
export BEE_COLOR_FAIL="#E"
export BEE_COLOR_RESET="#"
export BEE_LINE_RESET="#"
export BEE_CHECK_SUCCESS="BEE_CHECK_SUCCESS"
export BEE_CHECK_FAIL="BEE_CHECK_FAIL"
export BEE_RESULT="BEE_RESULT"
export BEE_ICON="BEE_ICON"
export BEE_WARN="BEE_WARN"
export BEE_ERR="BEE_ERR"

_set_beerc() { export BEE_RC="${BATS_TEST_DIRNAME}/fixtures/beerc.bash"; }
_set_beerc_with() {
  cp "${BATS_TEST_DIRNAME}/fixtures/beerc.bash" "${BATS_TEST_TMPDIR}/beerc.bash"
  export BEE_RC="${BATS_TEST_TMPDIR}/beerc.bash"
  for arg in "$@"; do
    echo "${arg}" >> "${BATS_TEST_TMPDIR}/beerc.bash"
  done
}
_set_beerc_fixture() { export BEE_RC="${BATS_TEST_DIRNAME}/fixtures/test-beerc.bash"; }
  # shellcheck disable=SC1090
_source_beerc() { source "${BEE_RC}"; }

_setup_beefile() {
  echo "$@" > "${BATS_TEST_TMPDIR}/Beefile"
  export BEE_FILE="${BATS_TEST_TMPDIR}/Beefile"
}

_setup_beefile :

_unset_beefile() {
  unset BEE_FILE
  rm "${BATS_TEST_TMPDIR}/Beefile"
}

_git_commit() {
  git -c user.name=bee -c user.email=bee -c commit.gpgsign=false commit "$@"
}

assert_bee_help() {
  assert_success
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

# shellcheck disable=SC2207,SC2068,SC2206
_comp() {
  export COMP_LINE="$1"
  export COMP_POINT="${#COMP_LINE}"
  export TEST_PLUGIN_QUIET=1
  run bee bee::comp
  actual=("${output}")
  actual=($(for i in ${actual[@]}; do echo "$i"; done | LC_ALL=C sort))
  if [[ -v 2 ]]; then
    expected=($2)
    expected=($(for i in ${expected[@]}; do echo "$i"; done | LC_ALL=C sort))
  fi
}
