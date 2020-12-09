#!/usr/bin/env bash
#
# Author: @sschmid
# Git LFS helper

lfs::_new() {
  echo "# lfs"
}

lfs::track_and_add() {
    git lfs track "${1}"
    git add "${1}"
}

lfs::untrack_and_add() {
    git lfs untrack "${1}"
    git rm --cached "$f"
    git add "${1}"
}

lfs::track_and_add_type() {
  local files=("$(find . -name "*.$1" -type f)")
  for f in "${files[@]}"; do
    lfs::track_and_add "$f"
  done
}

lfs::untrack_and_add_type() {
  local files=("$(find . -name "*.$1" -type f)")
  for f in "${files[@]}"; do
    lfs::untrack_and_add "$f"
  done
}
