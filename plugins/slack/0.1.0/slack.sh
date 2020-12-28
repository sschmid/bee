#!/usr/bin/env bash
#
# Author: @sschmid
# Send messages via slack

slack::_new() {
  echo "# slack"
  echo 'SLACK_WEBHOOK_URL="https://hooks.slack.com/services/abc123"'
  echo 'SLACK_AUTH_TOKEN="xoxa-xxxxxxxxx-xxxx"'
}

slack::message_webhook() {
  curl -s -X POST -H 'Content-type: application/json' --data "{\"text\":\"${1}\"}" "${SLACK_WEBHOOK_URL}"
}

slack::message() {
  local channel="${1}"
  local message="${2}"
  local parent_ts="${3:-}"
  local json=$(cat <<EOF
{
  "channel": "${channel}",
  "thread_ts": "${parent_ts}",
  "text": "${message}"
}
EOF
)
  curl -s -X POST -H 'Content-type: application/json' -H "Authorization: Bearer ${SLACK_AUTH_TOKEN}" --data "$json" https://slack.com/api/chat.postMessage
}

slack::upload() {
  local channels="${1}"
  local message="${2}"
  local file="${3}"
  local parent_ts="${4:-}"
  curl -s -F "file=@${file}" -F "thread_ts=${parent_ts}" -F "initial_comment=${message}" -F "channels=${channels}" -H "Authorization: Bearer ${SLACK_AUTH_TOKEN}" https://slack.com/api/files.upload
}
