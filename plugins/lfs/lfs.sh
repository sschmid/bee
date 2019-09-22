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
