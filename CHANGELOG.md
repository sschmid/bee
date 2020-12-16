## [0.37.2] - 2020-12-16
### Changed
- Store bee versions in ~/.bee/versions

## [0.37.1] - 2020-12-15
### Changed
- Fix `bee update` to only update system bee

## [0.37.0] - 2020-12-15
### Action required
- Rename your project `bee.sh` to `.beerc`
- Rename `PROJECT` to `BEE_PROJECT`
- Rename `RESOURCES` to `BEE_RESOURCES`

### Added
- Add support for custom .beerc path with `BEE_RC`
- Add support for fixed bee version per project by defining `BEE_VERSION` in your project `.beerc`

### Changed
- Rename `PROJECT` to `BEE_PROJECT`
- Rename `RESOURCES` to `BEE_RESOURCES`
- Extract `bee_runner.sh` from `bee_sh`

### Removed
- Remove `get` command

## [0.36.0] - 2020-12-09
### General
- Uninstall git lfs
- Replace lfs pointers with real files

### Added
- Add `lfs::untrack_and_add`
- Add `lfs::track_and_add_type`
- Add `lfs::untrack_and_add_type`

### Changed
- Rename `tag` to `BEE_VERSION` in `get`

## [0.35.0] - 2020-10-23
### Added
- Add `get` script to download a specific bee version
- Add `github::create_org_repo`
- Add `github::remove_team`
- Add `github::add_user`
- Add `github::remove_user`
- Add `Add github::me`

### Changed
- Print real BEE_RC path in help

## [0.34.0] - 2020-10-21
### Added
- Add support for custom .beerc path by exporting `BEE_RCs`

## [0.33.0] - 2020-10-15
### Added
- Add `github::set_topics`

## [0.32.0] - 2020-10-15
### Added
- Add slack::message using slack.com/api instead of webhook
- Add slack::upload
- trap INT and TERM

### Changed
- Rename `slack::message` to `slack::message_webhook`

## [0.31.0] - 2020-01-24
### Added
- Add `-silent`

## [0.30.0] - 2020-01-16
### Added
- Add `github::org`
- Add `github::teams`
- Add `github::add_team`
- Update `unity` readme

## [0.29.0] - 2020-01-07
### Fixed
- Fix `bee new <plugin>`
- Fix `bee res` not copying hidden files

## [0.28.1] - 2020-01-06
### Fixed
- Fix bee-completion setting `-u` flag

## [0.28.0] - 2020-01-06
### Added
- Add `bee uninstall`

## [0.27.0] - 2020-01-06
### Added
- Add `unity::sync_solution`
- Improve bash-completion

## [0.26.0] - 2019-09-22
### Added
- Improve bash-completion

### Changed
- Move source file to src

### Removed
- Delete bin/bee

## [0.25.0] - 2019-09-21
### Changed
- Update `ios` to work with Xcode 11

## [0.24.0] - 2019-09-21
### Changed
- Install bee-completion
- Use less instead of cat for help
- Simplify utils resources
- Simplify .gitattributes

### Remove
- Remove msbuild
- Remove nspec

## [0.23.0] - 2019-08-14
### Added
- Tag with optional suffix in `git::commit_release`
- Tag with optional suffix in `git::commit_release_sync_master`
- Add `unity::ping_project`
- Use `UNITY_USER`, `UNITY_PASSWORD` and `UNITY_SERIAL` for batchmode commands
- Add hints to `bee plugins` and `bee commands`
- Trap `EXIT` to show duration even when command fails

## [0.22.2] - 2019-06-13
### Added
- Always disable grep color for internal functions

## [0.22.1] - 2019-06-13
### Added
- Only source ~/.bashrc before executing plugin commands

## [0.22.0] - 2019-06-13
### Added
- Source ~/.bashrc before executing commands

## [0.21.0] - 2019-06-03
### Added
- Add `android::fingerprint`

## [0.20.0] - 2019-05-31
### Added
- Add `android::keyhash`

## [0.19.0] - 2019-05-24
### Added
- Add `deps` to help text
- Add `android::screenshot`
- Add `lfs` plugin
- Add `.editorconfig`
- Log unity output to stdout

### Changed
- Upload bitcode

## [0.18.0] - 2019-03-02
### Added
- Add `bee deps` to print missing dependencies
- Add `deps` to bee-completion

## [0.17.0] - 2019-02-20
### Changed
- `android::logcat` only prints logs from the app specified `ANDROID_PACKAGE`

### Upgrade
- Add `ANDROID_PACKAGE="com.company.myapp"` to bee.sh

## [0.16.0] - 2019-02-18
### Added
- Allow underscore in command names
- Only copy plugin template if pbcopy is available #1
- Add support for loading plugins on the fly without bee.sh
- Improve bash-completion
- Add `msbuild::debug_build`

## [0.15.0] - 2019-01-04
### Added
- Add `msbuild::restore`

## [0.14.0] - 2019-01-02
### Changed
- Rename `dotnet` to `msbuild`

### Upgrade
- Update usages of `dotnet` to `msbuild`

## [0.13.0] - 2018-12-09
### Added
- git lfs track *.png

### Upgrade
- git lfs migrate required a force push. Please reinstall bee and clone again

## [0.12.0] - 2018-12-09
### Added
- Improve bash-completion

## [0.11.0] - 2018-12-06
### Changed
- Rename `ios::archive` to `ios::archive_workspace`
- Add `ios::archive_project`

### Upgrade
- Replace calls to `ios::archive` with `ios::archive_workspace`

## [0.10.0] - 2018-11-24
### Changed
- Change `BEE_PLUGINS` to array and remove `BEE_USER_PLUGINS`

### Upgrade
- Update `~/.beerc` to use `BEE_PLUGINS` array

```
BEE_PLUGINS=("${BEE_HOME}/plugins" "${HOME}/.bee/plugins")
```

## [0.9.0] - 2018-11-13
### Added
- Add support for user plugins

### Upgrade
- Add `BEE_USER_PLUGINS="${HOME}/.bee/plugins"` to your `.beerc`

## [0.8.0] - 2018-11-04
### Added
- Add `nspec` plugin

### Changed
- Remove `dotnet::build_tests`
- Remove `dotnet::run_tests`
- Remove `dotnet::tests`

## [0.7.0] - 2018-10-24
### Added
- Add `android::start`

## [0.6.0] - 2018-10-22
### Changed
- Fix `doxygen::generate` cannot read `VERSION`

## [0.5.0] - 2018-10-21
### Changed
- Remove `utils::sync` deleting extraneous files
- Update template code to use ${RESOURCES}

## [0.4.0] - 2018-10-21
### Added
- Add `ANDROID_APK`
- Add `android::debug`
- Add `res` command

### Changed
- `android::install` uses `ANDROID_APK`
- Rename `utils::sync_files` to `utils::sync`
- `utils::sync` deletes extraneous files
- install script doesn't require user input

## [0.3.0] - 2018-10-10
### Added
- Add `android` plugin
- Add `slack` plugin
- Add `❤️` command
- Add `README.md` to all plugins

### Changed
- `ios::archive`: quiet xcodebuild
- `ios::export`: quiet xcodebuild
- Fix printing files in plugins folder
## [0.2.0] - 2018-10-01
### Added
- bee bash completion

## [0.1.0] - 2018-09-30
### Added
- bee
- plugins and templates
- install script
