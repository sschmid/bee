#!/usr/bin/env bash
#
# Author: @sschmid
# Shortcuts to adb

android::_new() {
  echo "# android"
  echo 'ANDROID_ADB="${HOME}/Library/Android/sdk/platform-tools/adb"
ANDROID_APK="Build/Android/${BEE_PROJECT}.apk"
ANDROID_PACKAGE="com.company.myapp"
ANDROID_KEYSTORE=.bee/android/keys.keystore
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

android::keyhash() {
  keytool -exportcert -alias "${ANDROID_PACKAGE}" -keystore "${ANDROID_KEYSTORE}"
  keytool -exportcert -alias "${ANDROID_PACKAGE}" -keystore "${ANDROID_KEYSTORE}" \
    | openssl sha1 -binary \
    | openssl base64
}

android::fingerprint() {
  keytool -list -v -keystore "${ANDROID_KEYSTORE}" -alias "${ANDROID_PACKAGE}" | grep --color=never -A12 "${ANDROID_PACKAGE}"
}
