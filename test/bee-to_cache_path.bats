setup() {
  load "test-helper.bash"
}

@test "file:// to cache path" {
  # shellcheck disable=SC2016
  run bee bee::to_cache_path 'file://${HOME}/bee/beehub'
  assert_success
  assert_output "beehub"
}

@test "https:// to cache path" {
  run bee bee::to_cache_path "https://github.com/sschmid/beehub.git"
  assert_success
  assert_output "github.com/sschmid/beehub"
}

@test "git:// to cache path" {
  run bee bee::to_cache_path "git://github.com/sschmid/beehub"
  assert_success
  assert_output "github.com/sschmid/beehub"
}

@test "git@ to cache path" {
  run bee bee::to_cache_path "git@github.com:sschmid/beehub.git"
  assert_success
  assert_output "github.com/sschmid/beehub"
}

@test "ssh:// to cache path" {
  run bee bee::to_cache_path "ssh://git@github.com/sschmid/beehub"
  assert_success
  assert_output "github.com/sschmid/beehub"
}

@test "warns when unsupported url" {
  run bee bee::to_cache_path "unknown"
  assert_success
  assert_output "${BEE_WARNING} Unsupported url: unknown"
}
