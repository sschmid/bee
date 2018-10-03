utils
=====
Please see templates folder for sample resources

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
