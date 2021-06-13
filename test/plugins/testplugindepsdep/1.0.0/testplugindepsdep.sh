#!/usr/bin/env bash

testplugindepsdep() {
  if (($#>0)); then
    echo "hello from testplugindepsdep 1.0.0 - $@"
  else
    echo "hello from testplugindepsdep 1.0.0"
  fi
}

testplugindepsdep::deps() {
  echo "testplugindeps:1.0.0"
}

testplugindepsdep::greet() {
  echo "greeting from testplugindepsdep 1.0.0"
  testplugindeps::greet "$@"
}
