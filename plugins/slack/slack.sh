#!/usr/bin/env bash
#
# Author: @sschmid
# Send messages via slack webhooks

slack::_new() {
  echo '# slack
SLACK_WEBHOOK_URL="https://hooks.slack.com/services/abc123"
'
}

slack::message() {
  curl -X POST -H 'Content-type: application/json' --data "{\"text\":\"${1}\"}" "${SLACK_WEBHOOK_URL}"
}
