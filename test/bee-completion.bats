# shellcheck disable=SC2030,SC2031
setup() {
  load "test-helper.bash"
  _set_beerc
  _set_test_modules
}

# shellcheck disable=SC2207
@test "completes with modules and plugins" {
  export TEST_BEE_PLUGINS_PATHS_CUSTOM=1
  _source_bee
  local expected=(testmodule othertestmodule testplugin othertestplugin testplugindeps testplugindepsdep testpluginmissingdep customtestplugin)
  assert_comp "bee " "${expected[*]}"
}

# shellcheck disable=SC2207
@test "doesn't complete plugins when folder doesn't exists" {
  export TEST_BEE_PLUGINS_PATHS_UNKNOWN=1
  _source_bee
  local expected=(testmodule othertestmodule)
  assert_comp "bee " "${expected[*]}"
}

@test "completes module" {
  _source_bee
  _comp "bee testmodule "
  actual=("${actual[@]:1}")
  assert_equal "${actual[*]}" "testmodulecomp"
}

@test "completes plugins" {
  _source_bee
  _comp "bee testplugin "
  actual=("${actual[@]:1}")
  assert_equal "${actual[*]}" "testplugincomp"
}

@test "completes plugins without comp function" {
  _source_bee
  _comp "bee othertestplugin "
  actual=("${actual[@]:1}")
  local expected=(greet help)
  assert_equal "${actual[*]}" "${expected[*]}"
}

@test "only completes first arg for plugins without comp function" {
  _source_bee
  _comp "bee othertestplugin help "
  actual=("${actual[@]:1}")
  assert_equal "${actual[*]}" ""
}
