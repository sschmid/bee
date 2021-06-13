#!/usr/bin/env bash

if [[ -v TESTPLUGIN_2_INIT ]]; then
  echo "# ERROR: already sourced"
  exit 1
fi

TESTPLUGIN_2_INIT=0

testplugin() {
  if (($# > 0)); then
    echo "hello from testplugin 2.0.0 - $@"
  else
    echo "hello from testplugin 2.0.0"
  fi
}

testplugin::help() {
  echo "testplugin 2.0.0 help"
}

testplugin::greet() {
  if (($# > 0)); then
    echo "greeting $@ from testplugin 2.0.0"
  else
    echo "greeting from testplugin 2.0.0"
  fi
}
