ios
===
This plugin comes with additional resources.
Please run `bee res ios` to copy all required files to you project.

`ios::archive_project`
--------------
- creates archive from project

`ios::archive_workspace`
--------------
- creates archive from workspace

`ios::export`
-------------
- exports archive from workspace

`ios::upload`
-------------
- uploads exported archive to [TestFlight](https://developer.apple.com/testflight/)


Dependencies
============
3rd party:
- `xcodebuild` - https://developer.apple.com/xcode/


Examples
========
```
$ bee ios::archive_project

$ bee ios::export

$ bee ios::upload
```
