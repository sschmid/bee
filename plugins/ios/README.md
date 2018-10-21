ios
===
This plugin comes with additional resources.
Please run `bee res ios` to copy all required files to you project.

`ios::archive`
--------------
- creates archive

`ios::export`
-------------
- exports archive

`ios::upload`
-------------
- uploads exported archive to [TestFlight](https://developer.apple.com/testflight/)

`ios::dist`
-----------
- runs `ios::archive`
- runs `ios::export`
- runs `ios::upload`


Dependencies
============
3rd party:
- `xcodebuild` - https://developer.apple.com/xcode/


Examples
========
```
$ bee ios::dist
```
