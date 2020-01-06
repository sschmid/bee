#!/usr/bin/env bash
#
# Author: @sschmid
# A set of commonly used utility functions

utils::_new() {
  echo "# utils"
  echo 'UTILS_RSYNC_INCLUDE="${RESOURCES}"/utils/rsync_include.txt
UTILS_RSYNC_EXCLUDE="${RESOURCES}"/utils/rsync_exclude.txt'
}

utils::clean_dir() {
  log_func "$@"
  rm -rf "$@"
  mkdir -p "$@"
}

utils::sync() {
  rsync -ahriI --include-from "${UTILS_RSYNC_INCLUDE}" --exclude-from "${UTILS_RSYNC_EXCLUDE}" "$@"
}
