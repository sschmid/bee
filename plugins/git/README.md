git
===

`git::merge_develop`
--------------------
- checkout and pull master
- merge develop
- checkout develop

`git::commit_release`
---------------------
- commit all changes to current branch
- create tag with current version

`git::commit_release_sync_master`
---------------------------------
- commit all changes to current branch
- checkout and pull master
- merge develop
- create tag with current version
- checkout develop

`git::push`
-----------
- push master
- push tags

`git::push_all`
---------------
- push master and develop
- push tags


Dependencies
============
- `version`

3rd party:
- `git` - https://git-scm.com


Examples
========
```
$ bee git::commit_release_sync_master
```
