#!/usr/bin/env bash

if [[ -v TESTPLUGIN_1_SOURCED ]]; then
  echo "# ERROR: already sourced"
  exit 1
fi

TESTPLUGIN_1_SOURCED=1
echo "# testplugin 1.0.0 sourced"

testplugin() {
  if (($# > 0)); then
    echo "hello from testplugin 1.0.0 - $@"
  else
    echo "hello from testplugin 1.0.0"
  fi
}

testplugin::help() {
  echo "testplugin 1.0.0 help"
}

testplugin::greet() {
  if (($# > 0)); then
    echo "greeting $@ from testplugin 1.0.0"
  else
    echo "greeting from testplugin 1.0.0"
  fi
}
