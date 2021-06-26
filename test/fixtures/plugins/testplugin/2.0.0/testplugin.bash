if [[ -v TESTPLUGIN_2_SOURCED ]]; then
  echo "# ERROR: already sourced"
  exit 1
fi

TESTPLUGIN_2_SOURCED=1
echo "# testplugin 2.0.0 sourced"

testplugin() {
  if (($# > 0)); then
    # shellcheck disable=SC2145
    echo "hello from testplugin 2.0.0 - $@"
  else
    echo "hello from testplugin 2.0.0"
  fi
}

testplugin::help() {
  echo "testplugin 2.0.0 help"
}

testplugin::greet() {
  if (($# > 0)); then
    # shellcheck disable=SC2145
    echo "greeting $@ from testplugin 2.0.0"
  else
    echo "greeting from testplugin 2.0.0"
  fi
}
