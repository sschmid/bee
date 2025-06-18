if [[ -v TEST_PLUGIN_2_SOURCED ]]; then
  echo "# ERROR: already sourced"
  exit 1
fi

TEST_PLUGIN_2_SOURCED=1
if [[ ! -v TEST_PLUGIN_QUIET ]]; then
  echo "# plugin_1 2.0.0 sourced"
fi

plugin_1() {
  if (( $# )); then
    # shellcheck disable=SC2145
    echo "hello from plugin_1 2.0.0 - $@"
  else
    echo "hello from plugin_1 2.0.0"
  fi
}

plugin_1::help() {
  echo "plugin_1 2.0.0 help"
}

plugin_1::greet() {
  if (( $# )); then
    # shellcheck disable=SC2145
    echo "greeting $@ from plugin_1 2.0.0"
  else
    echo "greeting from plugin_1 2.0.0"
  fi
}

plugin_1::comp() {
  echo "testplugincomp"
}
