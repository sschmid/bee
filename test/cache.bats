setup() {
  load "test-helper.bash"
  _set_beerc
  _source_beerc
  export BEE_OSTYPE="generic"
}

@test "opens cache path" {
  run bee cache
  assert_success
  assert_output "${BEE_CACHE_PATH}"
}

@test "shows help when unknown args" {
  run bee cache unknown
  assert_bee_help
}

@test "clears cache" {
  mkdir -p "${BEE_CACHE_PATH}"
  run bee cache --clear
  assert_success
  assert_dir_not_exist "${BEE_CACHE_PATH}"
}

@test "clears cache sub folder" {
  mkdir -p "${BEE_CACHE_PATH}/test"
  run bee cache --clear test
  assert_success
  assert_dir_not_exist "${BEE_CACHE_PATH}/test"
  assert_dir_exist "${BEE_CACHE_PATH}"
}

@test "ignores clearing cache sub folder that doesn't exist" {
  run bee cache --clear unknown
  assert_success
}

@test "completes bee cache with --clear" {
  assert_comp "bee cache " "--clear"
}

@test "completes bee cache --clear with sub folders" {
  mkdir -p "${BEE_CACHE_PATH}/test1"
  mkdir -p "${BEE_CACHE_PATH}/test2"
  local expected=(test1 test2)
  assert_comp "bee cache --clear " "${expected[*]}"
}

@test "no completion after sub folders" {
  mkdir -p "${BEE_CACHE_PATH}/test1"
  mkdir -p "${BEE_CACHE_PATH}/test2"
  assert_comp "bee cache --clear test1 "
}
