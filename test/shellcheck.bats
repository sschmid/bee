setup() {
  load 'test-helper.bash'
}

find_src() {
  cd "${PROJECT_ROOT}" || exit 1
  find "src" "etc" "test/fixtures" -type f -name "*.bash"
  find "test" -type f -maxdepth 1 -name "*.bash"
}

@test "shellcheck" {
  # shellcheck disable=SC2046
  run docker run --rm -v "${PROJECT_ROOT}:/mnt" koalaman/shellcheck $(find_src)
  assert_success
}
