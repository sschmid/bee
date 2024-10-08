if [[ -v TEST_PLUGIN_1_SOURCED ]]; then
  echo "# ERROR: already sourced"
  exit 1
fi

TEST_PLUGIN_1_SOURCED=1
if [[ ! -v TEST_PLUGIN_QUIET ]]; then
  echo "# testplugin 0.1.0 sourced"
fi

testplugin() {
  if (( $# )); then
    # shellcheck disable=SC2145
    echo "hello from testplugin 0.1.0 - $@"
  else
    echo "hello from testplugin 0.1.0"
  fi
}

testplugin::help() {
  echo "testplugin 0.1.0 help"
}

testplugin::greet() {
  if (( $# )); then
    # shellcheck disable=SC2145
    echo "greeting $@ from testplugin 0.1.0"
  else
    echo "greeting from testplugin 0.1.0"
  fi
}
