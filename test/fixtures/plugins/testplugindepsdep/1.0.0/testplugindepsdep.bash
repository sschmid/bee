if [[ ! -v TEST_PLUGIN_QUIET ]]; then
  echo "# testplugindepsdep 1.0.0 sourced"
fi

testplugindepsdep() {
  if (($#>0)); then
    # shellcheck disable=SC2145
    echo "hello from testplugindepsdep 1.0.0 - $@"
  else
    echo "hello from testplugindepsdep 1.0.0"
  fi
}

testplugindepsdep::greet() {
  echo "greeting from testplugindepsdep 1.0.0"
  testplugindeps::greet "$@"
  othertestplugin::greet "$@"
}
