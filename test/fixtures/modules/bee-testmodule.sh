#!/usr/bin/env bash

if [[ -v BEE_TESTMODULE_SOURCED ]]; then
  echo "# ERROR: already sourced"
  exit 1
fi

BEE_TESTMODULE_SOURCED=1
echo "# testmodule sourced"

bee::testmodule() {
  if (($# > 0)); then
    echo "hello from testmodule - $@"
  else
    echo "hello from testmodule"
  fi
}

bee::testmodule::help() {
  echo "testmodule help"
}
