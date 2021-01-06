#!/usr/bin/env bash

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
