setup() {
  load 'test-helper.bash'
}

find_src() {
  cd "${PROJECT_ROOT}" || exit 1
  find "src" "etc" "test/fixtures" -name "*.bash" -type f
  find "test" -name "*.bash" -type f -maxdepth 1
}

@test "shellcheck" {
  # shellcheck disable=SC2046
  run docker run --rm -v "${PROJECT_ROOT}:/mnt" koalaman/shellcheck $(find_src)
  assert_success
}
