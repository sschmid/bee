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

lfs::track_and_add_type() {
  local files=("$(find . -name "*.$1" -type f )")
  for f in "${files[@]}"; do
    git lfs track "$f"
  done
}
