if [[ -v CUSTOM_TESTPLUGIN_SOURCED ]]; then
  echo "# ERROR: already sourced"
  exit 1
fi

CUSTOM_TESTPLUGIN_SOURCED=1
if [[ ! -v TESTPLUGIN_QUIET ]]; then
  echo "# localplugin sourced"
fi

localplugin() {
  echo "hello from localplugin"
}

localplugin::deps() {
  echo "testplugin:1.0.0"
  echo "othertestplugin:1.0.0"
}
