echo "# testplugindeps 1.0.0 sourced"

testplugindeps() {
  if (($#>0)); then
    # shellcheck disable=SC2145
    echo "hello from testplugindeps 1.0.0 - $@"
  else
    echo "hello from testplugindeps 1.0.0"
  fi
}

testplugindeps::deps() {
  echo "testplugin:1.0.0"
  echo "othertestplugin:1.0.0"
}

testplugindeps::greet() {
  echo "greeting from testplugindeps 1.0.0"
  testplugin::greet "$@"
  othertestplugin::greet "$@"
}
