if [[ -v CUSTOM_TEST_PLUGIN_SOURCED ]]; then
  echo "# ERROR: already sourced"
  exit 1
fi

CUSTOM_TEST_PLUGIN_SOURCED=1
echo "# customtestplugin 1.0.0 sourced"

customtestplugin() {
  echo "hello from customtestplugin 1.0.0"
}

customtestplugin::deps() {
  echo "testplugin:1.0.0"
}
