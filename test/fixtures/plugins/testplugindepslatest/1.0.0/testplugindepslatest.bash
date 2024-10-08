if [[ ! -v TEST_PLUGIN_QUIET ]]; then
  echo "# testplugindepslatest 1.0.0 sourced"
fi

testplugindepslatest() {
  if (( $# > 0 )); then
    # shellcheck disable=SC2145
    echo "hello from testplugindepslatest 1.0.0 - $@"
  else
    echo "hello from testplugindepslatest 1.0.0"
  fi
}

testplugindepslatest::greet() {
  echo "greeting from testplugindepslatest 1.0.0"
  testplugin::greet "$@"
  othertestplugin::greet "$@"
}
