utils
=====
This plugin comes with additional resources.
Please run `bee res utils` to copy all required files to you project.

`utils::clean_dir`
------------------
- creates or cleans the specified directories

`utils::sync_files`
-------------------
- syncs files from the specified directory to the other using `rsync`


Dependencies
============
3rd party:
- `rsync` - https://rsync.samba.org


Examples
========
```
$ bee utils::clean_dir dir1 dir2

$ bee utils::sync_files dir1 dir2
```
