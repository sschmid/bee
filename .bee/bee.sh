#!/usr/bin/env bash

bee::release() {
  local version
  version="$(version::read)"
  changelog::merge
  git add .
  git commit -am "Release ${version}"
  git tag "${version}"
  git push origin main
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
