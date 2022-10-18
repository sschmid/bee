![Sherlog-Header](readme/bee-header.png)

# 🐝 bee - plugin-based bash automation

[![CI](https://github.com/sschmid/bee/actions/workflows/ci.yml/badge.svg)](https://github.com/sschmid/bee/actions/workflows/ci.yml)
[![Coverage Status](https://coveralls.io/repos/github/sschmid/bee/badge.svg)](https://gitter.im/sschmid/bee)
[![Chat](https://img.shields.io/badge/gitter-chat-ED1965.svg?logo=gitter)](https://github.com/sschmid/bee/actions/workflows/ci.yml)
[![Twitter](https://img.shields.io/twitter/follow/s_schmid)](https://twitter.com/intent/follow?original_referer=https%3A%2F%2Fgithub.com%2Fsschmid%2Fbee&screen_name=s_schmid&tw_p=followbutton)

## Automate Everything

bee is an open source platform aimed to simplify and standardize automation and deployment.
bee lets you automate every aspect of your development and release workflow.
bee runs everywhere - "it's just bash"

*__Automate the entire process from building your app to uploading it to the app stores__*

Combine bee with continuous integration tools such as [GitHub Actions](https://github.com/features/actions),
[Jenkins](https://jenkins.io), [Travis CI](https://travis-ci.org) or [TeamCity](https://www.jetbrains.com/teamcity/)
to automatically build and distribute your applications.

[**🐝 Continuous Integration**](https://github.com/sschmid/bee/wiki/Continuous-Integration)

## Plugins

bee is a bash package manager that runs plugins. Plugins are registered at beehub
which is the official bee plugin register: https://github.com/sschmid/beehub

You can register your own plugin at beehub by creating a pull request.
You can also create your own custom hubs or local plugins for your personal or private use.

Plugins allow you to customize and personalize bee to fit any requirement.
Are you missing a task or feature? Create your own plugins and contribute to beehub!
Share your plugins with the bee community so everyone can start saving time today.

Plugins and commands can easily be discovered with bee's built-in auto-completion! (see [bee-completion](#bee-completion))

[**🐝 Explore plugins**](https://github.com/sschmid/beehub)

--------------------------------------------------------------------------------

## Install

```
bash -c "$(curl -fsSL https://raw.githubusercontent.com/sschmid/bee/main/install)"
```

## bee completion

bee automatically completes plugins and makes working with them fun and easy.

Add auto-completion support for bee

```
echo "complete -C bee bee" >> ~/.bashrc
```

If you use [zsh](https://ohmyz.sh/) add those lines to your `~/.zshrc`

```
autoload bashcompinit
bashcompinit
complete -C bee bee
```

## Update

```
bee update
```

## Customize

bee is very flexible and can be customized heavily.
See [bee](https://github.com/sschmid/bee/blob/main/src/bee#L15-L32) and
[bee-run.bash](https://github.com/sschmid/bee/blob/main/src/bee-run.bash#L2-L5)
and overwrite default values in `~/.beerc`

--------------------------------------------------------------------------------

# Questions?

Frequently asked questions:

# [➡ FAQ](https://github.com/sschmid/bee/wiki/FAQ)

--------------------------------------------------------------------------------

## Example

Run individual plugin functions like this:

```bash
bee semver major
bee changelog merge
bee github create_release
```

or batch them for more efficiency

```bash
bee --batch \
    'semver major' \
    'changelog merge' \
    'unity execute_method BuildIOS' \
    'ios archive_project' \
    'ios export' \
    'ios upload' \
    'github create_release'
```

or compose custom functions using existing bee plugins

```bash
app::release() {
  semver::major
  changelog::merge
  unity::execute_method BuildIOS
  ios::archive_project
  ios::export
  ios::upload
  github::create_release
  slack::message $channel "New release $(semver::read)"
}
```

Discover and run your function using the bee bash completion

```
bee app release
```

Explanation
- `semver major` - bump the major version
- `changelog merge` - merge the latest changes into the changelog
- `unity execute_method BuildIOS` - build the Unity project
- `ios archive_project` - archive xcode project
- `ios export` - export archive
- `ios upload` - upload to [TestFlight](https://developer.apple.com/testflight/)
- `github create_release` - create a github release and optionally attach artifacts
- `slack message` - send a message via slack to notify the team about a new release

## Learn more

Read more about bee, checkout more examples and contribute your first own plugin

[**🐝 Open the bee wiki**](https://github.com/sschmid/bee/wiki)

<p align="center">
    <b>bee is free, but powered by your donations</b>
    <br />
    <a href="https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=M7WHTWP4GE75Y"><img src="https://www.paypalobjects.com/en_US/i/btn/btn_donate_LG.gif" alt="Donate">
    </a>
</p>
