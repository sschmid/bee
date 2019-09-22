#!/usr/bin/env bash
#
# Author: @sschmid
# Create github releases and upload attachments

github::_new() {
  echo "# github => $(github::_deps)"
  echo 'GITHUB_CHANGES=CHANGES.md
GITHUB_RELEASE_PREFIX="${PROJECT}-"
GITHUB_REPO="user/${PROJECT}"
GITHUB_ATTACHMENTS_ZIP=("Build/${PROJECT}.zip")
GITHUB_ACCESS_TOKEN="0123456789"'
}

github::_deps() {
  echo "version"
}

github::create_release() {
  log_func
  require jq
  local version="$(version::read)"
  local changes="$(cat "${GITHUB_CHANGES}")"
  local data="{\"tag_name\": \"${version}\", \"name\": \"${GITHUB_RELEASE_PREFIX}${version}\", \"body\": \"${changes//$'\n'/\\n}\"}"
  local response="$(curl -H "Authorization: token "${GITHUB_ACCESS_TOKEN}"" -d "${data}" https://api.github.com/repos/"${GITHUB_REPO}"/releases)"

  # Assets
  local id="$(echo "${response}" | jq .id)"
  local upload_url="https://uploads.github.com/repos/${GITHUB_REPO}/releases/${id}/assets"

  for f in "${GITHUB_ATTACHMENTS_ZIP[@]}"; do
    pushd "$(dirname "${f}")" > /dev/null
      echo "$(curl -H "Content-Type:application/zip" -H "Authorization: token "${GITHUB_ACCESS_TOKEN}"" --data-binary @"$(basename "${f}")" "${upload_url}"?name="$(basename "${f}")")" | tr -d "\r"
    popd > /dev/null
  done
}
