ios
===
Please see templates folder for sample resources

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
