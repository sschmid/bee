version 0.1.0
=============

`version::read`
---------------
- prints the current version found in `VERSION_PATH`

`version::write`
----------------
- writes specified version to `VERSION_PATH`

`version::bump_major`
---------------------
- bumps the major version

`version::bump_minor`
---------------------
- bumps the minor version

`version::bump_patch`
---------------------
- bumps the path version


Dependencies
============
none


Examples
========
```
$ bee version::write 1.2.3

$ bee bump_minor
```
