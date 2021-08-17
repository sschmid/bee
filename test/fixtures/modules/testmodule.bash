# bee::help
# testmodule ; help 1
# testmodule test ; help 2
# bee::help

if [[ -v BEE_TESTMODULE_SOURCED ]]; then
  echo "# ERROR: already sourced"
  exit 1
fi

BEE_TESTMODULE_SOURCED=1
echo "# testmodule sourced"

bee::testmodule() {
  if (($#)); then
    # shellcheck disable=SC2145
    echo "hello from testmodule - $@"
  else
    echo "hello from testmodule"
  fi
}

bee::testmodule::help() {
  echo "testmodule help"
}

bee::testmodule::comp() {
  echo "testmodulecomp"
}
