#!/usr/bin/env bash
#
# Author: @sschmid
# Commit and push releases

git::_new() {
  echo "# git => $(git::_deps)"
}

git::_deps() {
  echo "version"
}

git::merge_develop() {
  git checkout master
  git pull
  git merge develop
  git checkout develop
}

git::commit_release() {
  log_func
  local version="$(version::read)"
  git add .
  git commit -am "Release ${version}"
  git tag "${version}"
}

git::commit_release_sync_master() {
  log_func
  local version="$(version::read)"
  git add .
  git commit -am "Release ${version}"
  git checkout master
  git pull
  git merge develop
  git tag "${version}"
  git checkout develop
}

git::push() {
  log_func
  git push origin master
  git push --tags
}

git::push_all() {
  log_func
  git push origin master
  git push origin develop
  git push --tags
}
