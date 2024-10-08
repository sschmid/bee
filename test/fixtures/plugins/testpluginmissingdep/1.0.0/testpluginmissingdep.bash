if [[ ! -v TEST_PLUGIN_QUIET ]]; then
  echo "# testpluginmissingdep 1.0.0 sourced"
fi

testpluginmissingdep() {
  if (( $# )); then
    # shellcheck disable=SC2145
    echo "hello from testpluginmissingdep 1.0.0 - $@"
  else
    echo "hello from testpluginmissingdep 1.0.0"
  fi
}
