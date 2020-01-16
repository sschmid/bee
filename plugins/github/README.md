github
======
Please see
- https://github.com

`github::create_release`
------------------------
- creates new github release with current version
- attaches all zips in `GITHUB_ATTACHMENTS_ZIP` to github release

`github::github::org`
------------------------
- prints org details for `GITHUB_USER`

`github::teams`
------------------------
- prints teams for `GITHUB_REPO`

`github::add_team`
------------------------
- adds specified teamId with the specified permissions (pull | push | admin) to `GITHUB_REPO` in `GITHUB_ORG_ID`


Dependencies
============
- `version`

3rd party:
- `jq` - https://stedolan.github.io/jq/


Examples
========
```
$ bee github::create_release
$ bee github::teams
$ bee github::add_team 123 push
```
