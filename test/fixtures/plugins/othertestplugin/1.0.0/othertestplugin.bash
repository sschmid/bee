if [[ -v OTHERTEST_PLUGIN_SOURCED ]]; then
  echo "# ERROR: already sourced"
  exit 1
fi

OTHERTEST_PLUGIN_SOURCED=1
if [[ ! -v TEST_PLUGIN_QUIET ]]; then
  echo "# othertestplugin 1.0.0 sourced"
fi

othertestplugin() {
  if (( $# )); then
    # shellcheck disable=SC2145
    echo "hello from othertestplugin 1.0.0 - $@"
  else
    echo "hello from othertestplugin 1.0.0"
  fi
}

othertestplugin::help() {
  echo "othertestplugin 1.0.0 help"
}

othertestplugin::greet() {
  if (( $# )); then
    # shellcheck disable=SC2145
    echo "greeting $@ from othertestplugin 1.0.0"
  else
    echo "greeting from othertestplugin 1.0.0"
  fi
}
