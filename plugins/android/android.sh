#!/usr/bin/env bash
#
# Author: @sschmid
# Shortcuts to adb

android::_new() {
  echo '# android
ANDROID_ADB="${HOME}/Library/Android/sdk/platform-tools/adb"
ANDROID_APK="Build/Android/MyGame.apk"
'
}

android::devices() {
  "${ANDROID_ADB}" devices
}

android::install() {
  log_func "${ANDROID_APK}"
  "${ANDROID_ADB}" install -r "${ANDROID_APK}"
}

android::logcat() {
  "${ANDROID_ADB}" logcat "$@"
}

android::debug() {
  android::install
  android::logcat "$@"
}
