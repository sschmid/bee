android
=======

`android::devices`
------------------
- prints all connected devices

`android::install`
------------------
- installs apk to connected device

`android::logcat`
-----------------
- receives log messages from connected device using `adb logcat`


Dependencies
============
3rd party:
- `adb` - https://developer.android.com/studio/command-line/adb

Examples
========
```
$ bee android::devices

$ bee android::install MyGame.apk

$ bee android::logcat -s "Unity"
```
