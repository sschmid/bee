if [[ ! -v TEST_PLUGIN_QUIET ]]; then
  echo "# plugin_with_missing_deps 1.0.0 sourced"
fi

plugin_with_missing_deps() {
  if (( $# )); then
    # shellcheck disable=SC2145
    echo "hello from plugin_with_missing_deps 1.0.0 - $@"
  else
    echo "hello from plugin_with_missing_deps 1.0.0"
  fi
}
