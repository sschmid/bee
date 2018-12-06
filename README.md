# 🐝 bee - plugin-based automation - "it's just bash"

[![Join the chat at https://gitter.im/sschmid/bee](https://img.shields.io/badge/chat-on%20gitter-brightgreen.svg)](https://gitter.im/sschmid/bee)
[![Twitter @s_schmid](https://img.shields.io/badge/twitter-follow%20%40s__schmid-blue.svg)](https://twitter.com/intent/follow?original_referer=https%3A%2F%2Fgithub.com%2Fsschmid%2Fbee&screen_name=s_schmid&tw_p=followbutton)
[![Latest release](https://img.shields.io/github/release/sschmid/bee.svg)](https://github.com/sschmid/bee/releases)

## Automate your development and release process

bee is an open source platform aimed to simplify and standardize automation and deployment.
bee lets you automate every aspect of your development and release workflow.
bee runs everywhere - "it's just bash"

*__Automate the entire process from building your Unity project to uploading it to the app store__*

Combine bee with continuous integration tools such as [Jenkins](https://jenkins.io), [Travis CI](https://travis-ci.org) or [TeamCity](https://www.jetbrains.com/teamcity/) to automatically
build and distribute your applications.

[**🐝 Continuous Integration**](https://github.com/sschmid/bee/wiki/Continuous-Integration)

## Extending with Plugins

bee comes with a set of builtin plugins like 
`android`, `changelog`, `dotnet`, `doxygen`, `git`, `github`, `ios`, `nspec` `unity`, `version`, and more...

Plugins allow you to customize and personalize bee to fit any requirement.
Are you missing a task or feature? Create your own plugins and contribute to bee! Share
your plugins with the bee community so everyone can start saving time today.

[**🐝 Explore plugins**](https://github.com/sschmid/bee/tree/master/plugins)


## Example

```bash
release() {
  nspec::run
  version::bump_minor
  unity::execute_method BuildIOS
  ios::archive_project
  ios::export
  ios::upload
  changelog::merge
  git::commit_release_sync_master
  git::push_all
  github::create_release
  slack::message "New release $(version::read)"
}
```

```
$ bee release
```

- `nspec::run` - run the tests
- `version::bump_minor` - bump the minor version
- `unity::execute_method BuildIOS` - build the Unity project
- `ios::archive_project` - archive xcode project
- `ios::export` - export archive
- `ios::upload` - upload to [TestFlight](https://developer.apple.com/testflight/)
- `changelog::merge` - merge the latest changes into the changelog
- `git::commit_release_sync_master` - commit, tag and merge develop into master
- `git::push_all` - push develop, master and tags
- `github::create_release` - create a github release and optionally attach artifacts
- `slack::message` - send a message via slack to notify the team about a new release


## Install

```
$ bash -c "$(curl -fsSL https://raw.githubusercontent.com/sschmid/bee/master/install)"
```


## Update

```
$ bee update
```


## Customize

```
$ vim ~/.beerc
```


## Learn more

Read more about bee, checkout more examples and contribute your first own plugin

[**🐝 Open the bee wiki**](https://github.com/sschmid/bee/wiki)

<p align="center">
    <b>bee is free, but powered by your donations</b>
    <br />
    <a href="https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=M7WHTWP4GE75Y"><img src="https://www.paypalobjects.com/en_US/i/btn/btn_donate_LG.gif" alt="Donate">
    </a>
</p>
