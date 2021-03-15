#!/usr/bin/env bash

bee::release() {
  changelog::merge
  local version
  version="$(version::read)"
  git add .
  git commit -am "Release ${version}"
  git checkout main
  git pull
  git merge develop
  git tag "${version}"
  git checkout develop
  git push origin main
  git push origin develop
  git push --tags
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
