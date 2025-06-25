if [[ -v TEST_PLUGIN_1_SOURCED ]]; then
  echo "# ERROR: already sourced"
  exit 1
fi

TEST_PLUGIN_1_SOURCED=1

_plugin_log "# plugin_1 1.2.0 sourced"

plugin_1() {
  if (( $# )); then
    # shellcheck disable=SC2145
    echo "hello from plugin_1 1.2.0 - $@"
  else
    echo "hello from plugin_1 1.2.0"
  fi
}

plugin_1::help() {
  echo "plugin_1 1.2.0 help"
}

plugin_1::greet() {
  if (( $# )); then
    # shellcheck disable=SC2145
    echo "greeting $@ from plugin_1 1.2.0"
  else
    echo "greeting from plugin_1 1.2.0"
  fi
}
