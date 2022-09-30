# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.3.0] - 2022-09-30
### Added
- Run `bee::secrets` before running plugins

## [1.2.2] - 2022-09-29
### Added
- Add local plugins to Beefile.lock
- Add support for local plugins in `bee info`

### Fixed
- Fix resolve local plugins with local tag

## [1.2.1] - 2022-09-28
### Fixed
- Fix installing local plugin dependencies

## [1.2.0] - 2022-09-23
### Added
- Add `bee plugins --lock`

### Changed
- Exit `bee plugins` with error when missing plugins

### Fixed
- Check for `BEE_FILE` instead of hard coded Beefile path

## [1.1.0] - 2022-04-27
### Added
- Only map plugins when needed
- Add updating bee from a specific branch
- Add `TEST_BASH_VERSION` to support GitHub actions matrix
- Add FAQ link to readme
- Add instructions on how to test and build bee

### Changed
- Append to `.bashrc` in Dockerfile
- Change default branch to develop

### Removed
- Remove `VOLUME` in Dockerfile

## [1.0.0] - 2022-01-31
### Note
bee 1.0.0 is a complete rewrite from scratch
using [bats](https://github.com/bats-core/bats-core) for
test-driven development (TDD). As a result bee 1.0.0 is more flexible,
more efficient, more secure and scales better with an increasing number
of plugins. See https://github.com/sschmid/bee/projects/1

The new bee bash completion is faster and let's you add custom completions for
your plugins to make working with plugins even more convenient.

While most of the api stays the same, there are breaking changes.
Most importantly, plugin functions are now completed and invoked
without `::`, e.g.

```bash
bee github me   # instead of bee github::me
```

It's also recommended to backup and delete your existing `~/.beerc`
and let bee generate a new one by simply running any bee command.
Please merge the newly generated `~/.beerc` with your previous one if you want
to be backwards compatible and support bee versions < 1.0.0.

bee still supports older versions by specifying a version in your Beefile
```bash
BEE_VERSION=0.41.0
```

`Registries` are now referred to as `hubs`.

The new bee bash completion can be activated by adding this to your `~/.bashrc` or `~/.zshrc`

```bash
echo "complete -C bee bee" >> ~/.bashrc
```

Consider removing the old one by deleting `bee-completion.bash`
and removing it from your `~/.bashrc` or `~/.zshrc`
```bash
rm /usr/local/etc/bash_completion.d/bee-completion.bash
```

### Added
- Add bats and unit tests
- Add `os` directory to support various platforms like macOS, alpine, Windows WSL, etc.
- `bee install` generates `Beefile.lock` to share exact plugin versions across the team

### Changed
- Plugin functions are now completed and invoked without `::`,
  - e.g. `bee github me` instead of `bee github::me`
- Plugin dependencies now must be stored in `plugin.json` instead of `myplugin::deps`
- Hubs now must use `plugin.json` instead of `plugin.sh`
- Prefix all bee functions, e.g
  - `bee::log_info` instead of `log_info`,
  - `bee::job` instead of `job`
- bee api changes, see `bee --help`
- Use `complete -C bee bee` instead of `source /usr/local/etc/bash_completion.d/bee-completion.bash`

### Removed
- Remove short options like `-v` in favour of long options like `--verbose`
- Remove `bee changelog`
- Remove `bee commands`
- Remove `bee depstree`
- Remove `bee donate`
- Remove `bee reinstall`
- Remove `bee switch`
- Remove `bee uninstall`

## [0.41.0] - 2021-10-11
### Changed
- Rename `BEE_RC` to `BEEFILE`

## [0.40.0] - 2021-09-20
### Added
- Add help text when plugins are missing
- Cache docker apk add

### Changed
- Rename project's `.beerc` to `Beefile`
- Update install url to use main branch

## [0.39.1] - 2021-05-11
### Added
- Pass exit code to BEE_EXIT_TRAPS

## [0.39.0] - 2021-04-14
### Action required
- Delete `master` branch and use `main` branch
- Update bee symlink `ln -sf /usr/local/opt/bee/src/bee /usr/local/bin/bee`
- Update your `~/.beerc` and specify plugin registries
```sh
BEE_PLUGIN_REGISTRIES=(
  https://github.com/sschmid/beehub.git
)
```

Plugins have been removed from this repository and moved to their own repositories.

By the time of this release, these plugins are available:
- https://github.com/sschmid/bee-android
- https://github.com/sschmid/bee-changelog
- https://github.com/sschmid/bee-github
- https://github.com/sschmid/bee-ios
- https://github.com/sschmid/bee-macos
- https://github.com/sschmid/bee-sample
- https://github.com/sschmid/bee-slack
- https://github.com/sschmid/bee-tree
- https://github.com/sschmid/bee-unity
- https://github.com/sschmid/bee-version

bee now functions as a plugin launcher with package management functionality.
The plugins above are registered at beehub which is the
official bee plugin register: https://github.com/sschmid/beehub

You can register your own plugin at beehub by creating a pull request. You can
also create your own custom register for your personal or private plugins.

Please refer to the [README.md](https://github.com/sschmid/bee/blob/main/README.md) for more information.

### Added
- Add support for external plugin registries (beehub: https://github.com/sschmid/beehub)
- Add support for plugin versions
- Load adhoc plugins with all dependencies
- Prevent sourcing already sourced plugins
- Use bash strict mode
- Add `bee changelog`
- Add `bee job`
- Add `commands` search filter
- Add `bee lint`
- Add `bee hash`
- Add `bee pull`
- Add `bee install`
- Add `bee reinstall`
- Add `bee uninstall` for plugins
- Add `bee info`
- Add `bee outdated`
- Add `bee depstree`
- Add `bee batch`
- Add `bee cache`
- Add `bee switch`
- Add plugin traps
- Add global force option `bee -f`
- Add global ssh option `bee -p`
- Only log if `BEE_SILENT` is `0`
- Ask before uninstalling
- Add Dockerfile

### Changed
- Delete `master` branch and use `main` branch
- Rename bee.sh to bee
- Merge all bee source files into one file
- Rename `--silent` to `-s`
- Rename `--verbose` to `-v`
- Rename templates folder to resources
- Rename `log_strong` to `log_info`
- Change warning and error emojis
- Refactoring

### Removed
- Delete all plugins and use beehub

## [0.38.0] - 2020-12-16
### Added
- Add `macos::notification`

## [0.37.3] - 2020-12-16
### Added
- Add bee_migration_0370.sh

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

[Unreleased]: https://github.com/sschmid/bee/compare/1.3.0...HEAD
[1.3.0]: https://github.com/sschmid/bee/compare/1.2.2...1.3.0
[1.2.2]: https://github.com/sschmid/bee/compare/1.2.1...1.2.2
[1.2.1]: https://github.com/sschmid/bee/compare/1.2.0...1.2.1
[1.2.0]: https://github.com/sschmid/bee/compare/1.1.0...1.2.0
[1.1.0]: https://github.com/sschmid/bee/compare/1.0.0...1.1.0
[1.0.0]: https://github.com/sschmid/bee/compare/0.41.0...1.0.0
[0.41.0]: https://github.com/sschmid/bee/compare/0.40.0...0.41.0
[0.40.0]: https://github.com/sschmid/bee/compare/0.39.1...0.40.0
[0.39.1]: https://github.com/sschmid/bee/compare/0.39.0...0.39.1
[0.39.0]: https://github.com/sschmid/bee/compare/0.38.0...0.39.0
[0.38.0]: https://github.com/sschmid/bee/compare/0.37.3...0.38.0
[0.37.3]: https://github.com/sschmid/bee/compare/0.37.2...0.37.3
[0.37.2]: https://github.com/sschmid/bee/compare/0.37.1...0.37.2
[0.37.1]: https://github.com/sschmid/bee/compare/0.37.0...0.37.1
[0.37.0]: https://github.com/sschmid/bee/compare/0.36.0...0.37.0
[0.36.0]: https://github.com/sschmid/bee/compare/0.35.0...0.36.0
[0.35.0]: https://github.com/sschmid/bee/compare/0.34.0...0.35.0
[0.34.0]: https://github.com/sschmid/bee/compare/0.33.0...0.34.0
[0.33.0]: https://github.com/sschmid/bee/compare/0.32.0...0.33.0
[0.32.0]: https://github.com/sschmid/bee/compare/0.31.0...0.32.0
[0.31.0]: https://github.com/sschmid/bee/compare/0.30.0...0.31.0
[0.30.0]: https://github.com/sschmid/bee/compare/0.29.0...0.30.0
[0.29.0]: https://github.com/sschmid/bee/compare/0.28.1...0.29.0
[0.28.1]: https://github.com/sschmid/bee/compare/0.28.0...0.28.1
[0.28.0]: https://github.com/sschmid/bee/compare/0.27.0...0.28.0
[0.27.0]: https://github.com/sschmid/bee/compare/0.26.0...0.27.0
[0.26.0]: https://github.com/sschmid/bee/compare/0.25.0...0.26.0
[0.25.0]: https://github.com/sschmid/bee/compare/0.24.0...0.25.0
[0.24.0]: https://github.com/sschmid/bee/compare/0.23.0...0.24.0
[0.23.0]: https://github.com/sschmid/bee/compare/0.22.2...0.23.0
[0.22.2]: https://github.com/sschmid/bee/compare/0.22.1...0.22.2
[0.22.1]: https://github.com/sschmid/bee/compare/0.22.0...0.22.1
[0.22.0]: https://github.com/sschmid/bee/compare/0.21.0...0.22.0
[0.21.0]: https://github.com/sschmid/bee/compare/0.20.0...0.21.0
[0.20.0]: https://github.com/sschmid/bee/compare/0.19.0...0.20.0
[0.19.0]: https://github.com/sschmid/bee/compare/0.18.0...0.19.0
[0.18.0]: https://github.com/sschmid/bee/compare/0.17.0...0.18.0
[0.17.0]: https://github.com/sschmid/bee/compare/0.16.0...0.17.0
[0.16.0]: https://github.com/sschmid/bee/compare/0.15.0...0.16.0
[0.15.0]: https://github.com/sschmid/bee/compare/0.14.0...0.15.0
[0.14.0]: https://github.com/sschmid/bee/compare/0.13.0...0.14.0
[0.13.0]: https://github.com/sschmid/bee/compare/0.12.0...0.13.0
[0.12.0]: https://github.com/sschmid/bee/compare/0.11.0...0.12.0
[0.11.0]: https://github.com/sschmid/bee/compare/0.10.0...0.11.0
[0.10.0]: https://github.com/sschmid/bee/compare/0.9.0...0.10.0
[0.9.0]: https://github.com/sschmid/bee/compare/0.8.0...0.9.0
[0.8.0]: https://github.com/sschmid/bee/compare/0.7.0...0.8.0
[0.7.0]: https://github.com/sschmid/bee/compare/0.6.0...0.7.0
[0.6.0]: https://github.com/sschmid/bee/compare/0.5.0...0.6.0
[0.5.0]: https://github.com/sschmid/bee/compare/0.4.0...0.5.0
[0.4.0]: https://github.com/sschmid/bee/compare/0.3.0...0.4.0
[0.3.0]: https://github.com/sschmid/bee/compare/0.2.0...0.3.0
[0.2.0]: https://github.com/sschmid/bee/compare/0.1.0...0.2.0
[0.1.0]: https://github.com/sschmid/bee/releases/tag/0.1.0
