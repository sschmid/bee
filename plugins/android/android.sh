#!/usr/bin/env bash
#
# Author: @sschmid
# Shortcuts to adb

android::_new() {
  echo "# android"
  echo 'ANDROID_ADB="${HOME}/Library/Android/sdk/platform-tools/adb"
ANDROID_APK="Build/Android/${PROJECT}.apk"
ANDROID_PACKAGE="com.company.myapp"
ANDROID_ACTIVITY="${ANDROID_PACKAGE}/com.unity3d.player.UnityPlayerNativeActivity"'
}

android::devices() {
  "${ANDROID_ADB}" devices
}

android::install() {
  log_func "${ANDROID_APK}"
  "${ANDROID_ADB}" install -r "${ANDROID_APK}"
}

android::start() {
  log_func "${ANDROID_APK}"
  "${ANDROID_ADB}" shell am start -n "${ANDROID_ACTIVITY}"
}

android::logcat() {
  "${ANDROID_ADB}" logcat --pid "$("${ANDROID_ADB}" shell pidof "${ANDROID_PACKAGE}")" "$@"
}

android::debug() {
  android::install
  android::start
  sleep 1
  android::logcat "$@"
}

android::screenshot() {
  "${ANDROID_ADB}" shell screencap -p /sdcard/screenshot.png
  "${ANDROID_ADB}" pull /sdcard/screenshot.png
  "${ANDROID_ADB}" shell rm /sdcard/screenshot.png
}
