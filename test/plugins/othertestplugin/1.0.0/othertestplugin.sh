#!/usr/bin/env bash

if [[ -v OTHER_TESTPLUGIN_1_INIT ]]; then
  echo "# ERROR: already sourced"
  exit 1
fi

OTHER_TESTPLUGIN_1_INIT=0

othertestplugin() {
  if (($# > 0)); then
    echo "hello from othertestplugin 1.0.0 - $@"
  else
    echo "hello from othertestplugin 1.0.0"
  fi
}

othertestplugin::help() {
  echo "othertestplugin 1.0.0 help"
}

othertestplugin::greet() {
  if (($# > 0)); then
    echo "greeting $@ from othertestplugin 1.0.0"
  else
    echo "greeting from othertestplugin 1.0.0"
  fi
}
