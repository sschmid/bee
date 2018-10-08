#!/usr/bin/env bash
#
# Author: @sschmid
# Read, write and bump version numbers

version::_new() {
  echo '# version
VERSION_PATH=version.txt'
}

version::read() {
  assert_file VERSION_PATH
  cat "${VERSION_PATH}"
}

version::write() {
  echo "$1" > "${VERSION_PATH}"
  cat "${VERSION_PATH}"
}

version::bump_major() {
  log_func
  assert_file VERSION_PATH
  local version="$(version::read)"
  local major="${version%%.*}"
  version::write "$((major+1)).0.0"
}

version::bump_minor() {
  log_func
  assert_file VERSION_PATH
  local version="$(version::read)"
  local major="${version%%.*}"
  local sv="${version%.*}"
  local minor="${sv##*.}"
  version::write "${major}.$((minor+1)).0"
}

version::bump_patch() {
  log_func
  assert_file VERSION_PATH
  local version="$(version::read)"
  local major="${version%%.*}"
  local sv="${version%.*}"
  local minor="${sv##*.}"
  local patch="${version##*.}"
  version::write "${major}.${minor}.$((patch+1))"
}
