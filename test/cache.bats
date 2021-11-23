setup() {
  load "test-helper.bash"
  _set_beerc
  _source_bee
}

@test "is not executable" {
  assert_file_not_executable "${PROJECT_ROOT}/src/modules/cache.bash"
}

@test "prints cache path" {
  run _strict bee::run cache
  assert_output "${BEE_CACHES_PATH}"
}

@test "shows help when unknown args" {
  run _strict bee::run cache unknown
  assert_bee_help
}

@test "deletes cache" {
  mkdir -p "${BEE_CACHES_PATH}"
  run _strict bee::run cache rm
  assert_dir_not_exist "${BEE_CACHES_PATH}"
}

@test "completes cache with rm" {
  assert_comp "bee cache " "rm"
}

@test "no comp for cache rm" {
  assert_comp "bee cache rm "
}
