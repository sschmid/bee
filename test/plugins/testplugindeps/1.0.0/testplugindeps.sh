#!/usr/bin/env bash

testplugindeps() {
  if (($#>0)); then
    echo "hello from testplugindeps 1.0.0 - $@"
  else
    echo "hello from testplugindeps 1.0.0"
  fi
}

testplugindeps::deps() {
  echo "testplugin:1.0.0"
  echo "testplugin:2.0.0"
}

testplugindeps::greet() {
  echo "greeting from testplugindeps 1.0.0"
  testplugin::greet "$@"
}
