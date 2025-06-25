if [[ -v OTHERTEST_PLUGIN_SOURCED ]]; then
  echo "# ERROR: already sourced"
  exit 1
fi

OTHERTEST_PLUGIN_SOURCED=1

_plugin_log "# plugin_2 1.0.0 sourced"

plugin_2() {
  if (( $# )); then
    # shellcheck disable=SC2145
    echo "hello from plugin_2 1.0.0 - $@"
  else
    echo "hello from plugin_2 1.0.0"
  fi
}

plugin_2::help() {
  echo "plugin_2 1.0.0 help"
}

plugin_2::greet() {
  if (( $# )); then
    # shellcheck disable=SC2145
    echo "greeting $@ from plugin_2 1.0.0"
  else
    echo "greeting from plugin_2 1.0.0"
  fi
}
