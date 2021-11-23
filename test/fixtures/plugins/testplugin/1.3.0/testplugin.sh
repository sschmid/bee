if [[ -v TESTPLUGIN_1_SOURCED ]]; then
  echo "# ERROR: already sourced"
  exit 1
fi

TESTPLUGIN_1_SOURCED=1
echo "# testplugin 1.3.0 sourced"

testplugin() {
  if (($#)); then
    # shellcheck disable=SC2145
    echo "hello from testplugin 1.3.0 - $@"
  else
    echo "hello from testplugin 1.3.0"
  fi
}

testplugin::help() {
  echo "testplugin 1.3.0 help"
}

testplugin::greet() {
  if (($#)); then
    # shellcheck disable=SC2145
    echo "greeting $@ from testplugin 1.3.0"
  else
    echo "greeting from testplugin 1.3.0"
  fi
}
