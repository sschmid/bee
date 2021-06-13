#!/usr/bin/env bash

TESTPLUGIN_VERSION="1.0.0"

testplugin() {
  if (($# > 0)); then
    echo "hello from testplugin ${TESTPLUGIN_VERSION} - $@"
  else
    echo "hello from testplugin ${TESTPLUGIN_VERSION}"
  fi
}

testplugin::help() {
  echo "testplugin ${TESTPLUGIN_VERSION} help"
}

testplugin::greet() {
  if (($# > 0)); then
    echo "greeting $@ from testplugin ${TESTPLUGIN_VERSION}"
  else
    echo "greeting from testplugin ${TESTPLUGIN_VERSION}"
  fi
}
