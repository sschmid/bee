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

