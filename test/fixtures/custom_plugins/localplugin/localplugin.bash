if [[ -v CUSTOM_TESTPLUGIN_SOURCED ]]; then
  echo "# ERROR: already sourced"
  exit 1
fi

CUSTOM_TESTPLUGIN_SOURCED=1
echo "# localplugin sourced"

localplugin() {
  echo "hello from localplugin"
}

localplugin::deps() {
  echo "testplugin:1.0.0"
}
