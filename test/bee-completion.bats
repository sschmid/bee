# shellcheck disable=SC2030,SC2031
setup() {
  load "test-helper.bash"
  _set_beerc
  _set_test_modules
  FILE_PATH="${PROJECT_ROOT}/etc/bash_completion.d/bee-completion.bash"
  # shellcheck disable=SC1090
  source "${FILE_PATH}"
}

@test "is not executable" {
  assert_file_not_executable "${FILE_PATH}"
}

# shellcheck disable=SC2207
@test "completes with modules and plugins" {
  COMP_WORDS=(bee)
  COMP_CWORD=1
  export TEST_BEE_PLUGINS_PATHS_CUSTOM=1
  _bee_completions
  local expected=(
    testmodule othertestmodule
    testplugin othertestplugin testplugindeps testplugindepsdep testpluginmissingdep customtestplugin
  )
  expected=($(for i in "${expected[@]}"; do echo "$i"; done | sort))
  COMPREPLY=($(for i in "${COMPREPLY[@]}"; do echo "$i"; done | sort))
  assert_equal "${COMPREPLY[*]}" "${expected[*]}"
}

# shellcheck disable=SC2207
@test "doesn't complete plugins when folder doesn't exists" {
  COMP_WORDS=(bee)
  COMP_CWORD=1
  export TEST_BEE_PLUGINS_PATHS_UNKNOWN=1
  _bee_completions
  local expected=(
    testmodule othertestmodule
  )
  expected=($(for i in "${expected[@]}"; do echo "$i"; done | sort))
  COMPREPLY=($(for i in "${COMPREPLY[@]}"; do echo "$i"; done | sort))
  assert_equal "${COMPREPLY[*]}" "${expected[*]}"
}

@test "completes module" {
  COMP_WORDS=(bee testmodule)
  COMP_CWORD=2
  _bee_completions
  assert_equal "${COMPREPLY[-1]}" "testmodulecomp"
}

@test "completes plugins" {
  COMP_WORDS=(bee testplugin)
  COMP_CWORD=2
  _bee_completions
  assert_equal "${COMPREPLY[-1]}" "testplugincomp"
}
