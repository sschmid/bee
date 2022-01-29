if [[ ! -v TEST_PLUGIN_QUIET ]]; then
  echo "# testplugindeps 1.0.0 sourced"
fi

testplugindeps() {
  if (($#>0)); then
    # shellcheck disable=SC2145
    echo "hello from testplugindeps 1.0.0 - $@"
  else
    echo "hello from testplugindeps 1.0.0"
  fi
}

testplugindeps::greet() {
  echo "greeting from testplugindeps 1.0.0"
  testplugin::greet "$@"
  othertestplugin::greet "$@"
}
