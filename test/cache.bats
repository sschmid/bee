setup() {
  load "test-helper.bash"
  _set_beerc
  _source_bee
  MODULE_PATH="${PROJECT_ROOT}/src/modules/cache.bash"
}

@test "is not executable" {
  assert_file_not_executable "${MODULE_PATH}"
}

@test "prints cache path" {
  run _strict bee::run cache
  assert_output "${BEE_CACHES_PATH}"
}

@test "shows help when unknown args" {
  run _strict bee::run cache unkown
  assert_output --partial "plugin-based bash automation"
}

@test "deletes cache" {
  mkdir -p "${BEE_CACHES_PATH}"
  assert_dir_exist "${BEE_CACHES_PATH}"

  run _strict bee::run cache rm
  assert_dir_not_exist "${BEE_CACHES_PATH}"
}
