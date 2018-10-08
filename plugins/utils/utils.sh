#!/usr/bin/env bash
#
# Author: @sschmid
# A set of commonly used utility functions

utils::_new() {
  echo '# utils
UTILS_RSYNC_INCLUDE=bee/utils/rsync_include.txt
UTILS_RSYNC_EXCLUDE=bee/utils/rsync_exclude.txt'
}

utils::clean_dir() {
  log_func "$@"
  rm -rf "$@"
  mkdir -p "$@"
}

utils::sync_files() {
  rsync -ai --include-from "${UTILS_RSYNC_INCLUDE}" --exclude-from "${UTILS_RSYNC_EXCLUDE}" "$1" "$2"
}
