github
======
Please see https://github.com

`github::create_release`
------------------------
- creates new github release with current version
- attaches all zips in `GITHUB_ATTACHMENTS_ZIP` to github release


Dependencies
============
- `version`

3rd party:
- `jq` - https://stedolan.github.io/jq/


Examples
========
```
$ bee github::create_release
```
