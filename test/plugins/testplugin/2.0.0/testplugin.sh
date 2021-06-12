#!/usr/bin/env bash

testplugin() {
  if (($#>0)); then
    echo "hello from testplugin 2.0.0 - $@"
  else
    echo "hello from testplugin 2.0.0"
  fi
}
