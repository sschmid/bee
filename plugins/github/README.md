github
======
Please see
- https://github.com

`github::create_org_repo`
------------------------
- creates new github organization repository with the specified name private boolean

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
- adds the specified teamId with the specified permissions (pull | push | admin) to `GITHUB_REPO` in `GITHUB_ORG_ID`

`github::remove_team`
------------------------
- removes the specified teamId from `GITHUB_REPO` in `GITHUB_ORG_ID`

`github::set_topics`
------------------------
- sets specified topics on `GITHUB_REPO`


Dependencies
============
- `version`

3rd party:
- `jq` - https://stedolan.github.io/jq/


Examples
========
```
$ bee github::create_org_repo "Game" true
$ bee github::create_release
$ bee github::teams
$ bee github::add_team 123 push
$ bee github::set_topics game
```
