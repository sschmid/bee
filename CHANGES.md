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
