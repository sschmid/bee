#!/usr/bin/env bash
#
# Author: @sschmid
# macOS helpers

macos::_new() {
  echo "# macos"
}

macos::notification() {
  osascript -e 'display notification "'"${2}"'" with title "'"${1}"'"'
}
