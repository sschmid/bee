#!/usr/bin/env bash
#
# Author: @sschmid
# Shortcuts to adb

android::_new() {
  echo '# android
ANDROID_ADB="${HOME}/Library/Android/sdk/platform-tools/adb"
'
}

android::devices() {
  "${ANDROID_ADB}" devices
}

android::install() {
  "${ANDROID_ADB}" install -r "$@"
}

android::logcat() {
  "${ANDROID_ADB}" logcat "$@"
}
