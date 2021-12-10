# shellcheck disable=SC2030,SC2031
setup() {
  load "test-helper.bash"
}

@test "logs env var" {
  export my_var="test1"
  run bee env my_var
  assert_success
  assert_output "test1"
}

@test "logs multiple env vars" {
  export my_var1="test1" my_var2="test2"
  run bee env my_var1 my_var2
  assert_success
  cat << EOF | assert_output -
test1
test2
EOF
}

@test "logs env var even when quiet" {
  export my_var="test2"
  run bee --quiet env my_var
  assert_success
  assert_output "test2"
}
