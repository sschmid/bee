if [[ ! -v TEST_PLUGIN_QUIET ]]; then
  echo "# plugin_with_deps 1.0.0 sourced"
fi

plugin_with_deps() {
  if (( $# > 0 )); then
    # shellcheck disable=SC2145
    echo "hello from plugin_with_deps 1.0.0 - $@"
  else
    echo "hello from plugin_with_deps 1.0.0"
  fi
}

plugin_with_deps::greet() {
  echo "greeting from plugin_with_deps 1.0.0"
  plugin_1::greet "$@"
  plugin_2::greet "$@"
}
