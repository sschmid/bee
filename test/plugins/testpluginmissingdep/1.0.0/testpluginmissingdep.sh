#!/usr/bin/env bash

testpluginmissingdep() {
  if (($#>0)); then
    echo "hello from testpluginmissingdep 1.0.0 - $@"
  else
    echo "hello from testpluginmissingdep 1.0.0"
  fi
}

testpluginmissingdep::deps() {
  echo "testplugindepsdep:1.0.0"
  echo "missing:1.0.0"
  echo "othermissing:1.0.0"
}

testpluginmissingdep::greet() {
  echo "greeting from testpluginmissingdep 1.0.0"
}
