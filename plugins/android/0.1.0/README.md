android 0.1.0
=============

`android::devices`
------------------
- prints all connected devices

`android::install`
------------------
- installs apk `ANDROID_APK` to connected device

`android::start`
------------------
- starts `ANDROID_ACTIVITY` on connected device

`android::logcat`
-----------------
- prints log messages from connected device and
  app with pid for `ANDROID_PACKAGE` using `adb logcat --pid`

`android::debug`
-----------------
- runs `android::install`
- runs `android::start`
- runs `android::logcat`

`android::screenshot`
-----------------
- takes a screenshot on the device and saves it on your computer under screenshot.png

`android::keyhash`
-----------------
- creates key hash for `ANDROID_PACKAGE` in `ANDROID_KEYSTORE`
- confirm with enter twice

`android::fingerprint`
-----------------
- prints certificate fingerprints for `ANDROID_PACKAGE` in `ANDROID_KEYSTORE`
- confirm with enter


Dependencies
============
3rd party:
- `adb` - https://developer.android.com/studio/command-line/adb


Examples
========
```
$ bee android::devices

$ bee android::install

$ bee android::logcat -s "Unity"

$ bee android::debug -s "Unity"
```