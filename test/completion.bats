setup() {
  load "test-helper.bash"
  _set_test_beerc
  FILE_PATH="${PROJECT_ROOT}/etc/bee-completion.bash"
  # shellcheck disable=SC1090
  source "${FILE_PATH}"
}

@test "is not executable" {
  assert_file_not_executable "${FILE_PATH}"
}

@test "completes with modules and plugins" {
  COMP_WORDS=(bee)
  COMP_CWORD=1
  _bee_completions
  assert_equal "${COMPREPLY[*]}" "othertestmodule testmodule testplugindepsdep testplugin testplugindeps othertestplugin testpluginmissingdep"
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
