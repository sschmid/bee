#!/usr/bin/env bash
# Dec 2020

bee_migration_0390() {
  if [[ "${2}" == "README.md" ]]; then
    log_warn "${1} doesn't support plugin versions yet, please consider updating the plugin"
    echo "."
  else
    echo "${2}"
  fi
}
