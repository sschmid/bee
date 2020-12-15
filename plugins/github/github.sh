#!/usr/bin/env bash
#
# Author: @sschmid
# Create github releases and upload attachments

github::_new() {
  echo "# github => $(github::_deps)"
  echo 'GITHUB_CHANGES=CHANGES.md
GITHUB_RELEASE_PREFIX="${BEE_PROJECT}-"
GITHUB_USER="user"
GITHUB_REPO="${GITHUB_USER}/${BEE_PROJECT}"
GITHUB_ORG_ID="0123456789"
GITHUB_ATTACHMENTS_ZIP=("Build/${BEE_PROJECT}.zip")
GITHUB_ACCESS_TOKEN="0123456789"'
}

github::_deps() {
  echo "version"
}

github::create_org_repo() {
  curl -H "Authorization: token ${GITHUB_ACCESS_TOKEN}" -d "{\"name\": \"${1}\", \"private\": ${2}}" https://api.github.com/orgs/${GITHUB_USER}/repos
}

github::create_release() {
  log_func
  require jq
  local version="$(version::read)"
  local changes="$(cat "${GITHUB_CHANGES}")"
  local data="{\"tag_name\": \"${version}\", \"name\": \"${GITHUB_RELEASE_PREFIX}${version}\", \"body\": \"${changes//$'\n'/\\n}\"}"
  local response="$(curl -H "Authorization: token ${GITHUB_ACCESS_TOKEN}" -d "${data}" https://api.github.com/repos/"${GITHUB_REPO}"/releases)"

  # Assets
  local id="$(echo "${response}" | jq .id)"
  local upload_url="https://uploads.github.com/repos/${GITHUB_REPO}/releases/${id}/assets"

  for f in "${GITHUB_ATTACHMENTS_ZIP[@]}"; do
    pushd "$(dirname "${f}")" > /dev/null
      echo "$(curl -H "Content-Type:application/zip" -H "Authorization: token ${GITHUB_ACCESS_TOKEN}" --data-binary @"$(basename "${f}")" "${upload_url}"?name="$(basename "${f}")")" | tr -d "\r"
    popd > /dev/null
  done
}

github::org() {
  curl -H "Authorization: token ${GITHUB_ACCESS_TOKEN}" "https://api.github.com/orgs/${GITHUB_USER}"
}

github::teams() {
  curl -H "Authorization: token ${GITHUB_ACCESS_TOKEN}" "https://api.github.com/repos/${GITHUB_REPO}/teams"
}

github::add_team() {
  local data="{\"permission\": \"${2}\"}"
  curl -X PUT -H "Authorization: token ${GITHUB_ACCESS_TOKEN}" -d "${data}" "https://api.github.com/organizations/${GITHUB_ORG_ID}/team/${1}/repos/${GITHUB_REPO}"
}

github::remove_team() {
  curl -X DELETE -H "Authorization: token ${GITHUB_ACCESS_TOKEN}" "https://api.github.com/organizations/${GITHUB_ORG_ID}/team/${1}/repos/${GITHUB_REPO}"
}

github::me() {
  curl -H "Authorization: token ${GITHUB_ACCESS_TOKEN}" "https://api.github.com/user" | jq -r '.login'
}

github::add_user() {
  local data="{\"permission\": \"${2}\"}"
  curl -X PUT -H "Authorization: token ${GITHUB_ACCESS_TOKEN}" -d "${data}" "https://api.github.com/repos/${GITHUB_REPO}/collaborators/${1}"
}

github::remove_user() {
  curl -X DELETE -H "Authorization: token ${GITHUB_ACCESS_TOKEN}" "https://api.github.com/repos/${GITHUB_REPO}/collaborators/${1}"
}

github::set_topics() {
  local data="{\"names\":[\"${1}\"]}"
  curl -X PUT -H "Authorization: token ${GITHUB_ACCESS_TOKEN}" -H "Accept: application/vnd.github.mercy-preview+json" -d "${data}" "https://api.github.com/repos/${GITHUB_REPO}/topics"
}
