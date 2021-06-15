#!/usr/bin/env bash

if [[ -v BEE_OTHERTESTMODULE_SOURCED ]]; then
  echo "# ERROR: already sourced"
  exit 1
fi

BEE_OTHERTESTMODULE_SOURCED=1
echo "# othertestmodule sourced"

bee::othertestmodule() {
  if (($# > 0)); then
    echo "hello from othertestmodule - $@"
  else
    echo "hello from othertestmodule"
  fi
}

bee::othertestmodule::help() {
  echo "othertestmodule help"
}
