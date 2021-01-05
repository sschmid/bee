#!/usr/bin/env bash
#
# Author: @sschmid
# Prints folder and file overview

tree::_new() {
  echo "# tree"
  echo 'TREE_IGNORE="bin|obj|Build|Temp"
TREE_PATH=tree.txt'
}

tree::create() {
  bee::log_func
  require tree
  tree -I "${TREE_IGNORE}" --noreport -d > "${TREE_PATH}"
  tree -I "${TREE_IGNORE}" --noreport --dirsfirst >> "${TREE_PATH}"
  cat "${TREE_PATH}"
}
