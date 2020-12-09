lfs
===

`lfs::track_and_add`
--------------------
- lfs track && git add specified file

`lfs::untrack_and_add`
--------------------
- lfs untrack && git rm --cached && git add specified file

`lfs::track_and_add_type`
--------------------
- lfs::track_and_add specified file type found in the current folder and subfolders

`lfs::untrack_and_add_type`
--------------------
- lfs::untrack_and_add specified file type found in the current folder and subfolders


Dependencies
============
none

3rd party:
- `git` - https://git-scm.com
- `git lfs` - https://git-lfs.github.com


Examples
========
```
$ bee lfs lfs::track_and_add file.png
$ bee lfs lfs::track_and_add_type png
```
