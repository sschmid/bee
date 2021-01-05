#!/usr/bin/env bash
#
# Author: @sschmid
# Merge changes into changelog
# https://keepachangelog.com

changelog::_new() {
  echo "# changelog => $(changelog::_deps)"
  echo 'CHANGELOG_PATH=CHANGELOG.md
CHANGELOG_CHANGES=CHANGES.md'
}

changelog::_deps() {
  echo "version"
}

changelog::merge() {
  bee::log_func
  assert_file CHANGELOG_CHANGES

  if [[ ! -f "${CHANGELOG_PATH}" ]]; then
    touch "${CHANGELOG_PATH}"
  fi

  local tmp="${CHANGELOG_PATH}.tmp"
  local version="$(version::read)"
  echo "## [${version}] - $(date +%Y-%m-%d)" > "${tmp}"
  cat "${CHANGELOG_CHANGES}" >> "${tmp}"
  echo "" >> "${tmp}"
  cat "${CHANGELOG_PATH}" >> "${tmp}"
  mv "${tmp}" "${CHANGELOG_PATH}"
}
