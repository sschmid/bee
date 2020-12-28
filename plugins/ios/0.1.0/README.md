ios 0.1.0
=========
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
- exports archive

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
$ bee ios::archive_workspace

$ bee ios::export

$ bee ios::upload
```
