#!/usr/bin/env bash

echo "# testplugindepsdep 1.0.0 sourced"

testplugindepsdep() {
  if (($#>0)); then
    echo "hello from testplugindepsdep 1.0.0 - $@"
  else
    echo "hello from testplugindepsdep 1.0.0"
  fi
}

testplugindepsdep::deps() {
  echo "testplugindeps:1.0.0"
  echo "testplugin:1.0.0"
}

testplugindepsdep::greet() {
  echo "greeting from testplugindepsdep 1.0.0"
  testplugindeps::greet "$@"
  othertestplugin::greet "$@"
}
