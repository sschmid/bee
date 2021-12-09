setup() {
  load "test-helper.bash"
  _set_beerc
}

@test "doesn't complete plugins when folder doesn't exists" {
  _set_beerc_with 'BEE_PLUGINS_PATHS=(unknown)'
  local expected=(cache env job plugins update version)
  assert_comp "bee " "${expected[*]}"
}

@test "completes with plugins" {
  export TEST_BEE_PLUGINS_PATHS_CUSTOM=1
  local expected=(
    cache env job plugins update version
    testplugin testplugindeps testpluginmissingdep testplugindepsdep
    customtestplugin othertestplugin
  )
  assert_comp "bee " "${expected[*]}"
}

@test "completes plugins with comp function" {
  assert_comp "bee testplugin " testplugincomp
}

@test "completes plugins without comp function" {
  local expected=(greet help)
  assert_comp "bee othertestplugin " "${expected[*]}"
}

@test "only completes first arg for plugins without comp function" {
  assert_comp "bee othertestplugin help "
}
