#!/usr/bin/env bash
PROJECT="bee"
PLUGINS=(changelog git github version)
RESOURCES=.bee

# changelog => version
CHANGELOG_PATH=CHANGELOG.md
CHANGELOG_CHANGES=CHANGES.md

# github => version
GITHUB_CHANGES=CHANGES.md
GITHUB_RELEASE_PREFIX="${PROJECT}-"
GITHUB_REPO="sschmid/bee"
GITHUB_ATTACHMENTS_ZIP=()
source "${HOME}/.bee/github"

# version
VERSION_PATH=version.txt

# bee
bee::release() {
  log_func
  changelog::merge
  git::commit_release_sync_master
  git::push_all
  log "bzzz... giving GitHub some time to process..."
  sleep 10
  github::create_release
}

bee::release_major() {
  version::bump_major
  bee::release
}

bee::release_minor() {
  version::bump_minor
  bee::release
}

bee::release_patch() {
  version::bump_patch
  bee::release
}
