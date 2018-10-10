#!/usr/bin/env bash
#
# Author: @sschmid
# Send messages via slack

slack::_new() {
  echo '# slack
SLACK_WEBHOOK_URL="https://hooks.slack.com/services/abcdefgh123456"
'
}

slack::message() {
  curl -X POST -H 'Content-type: application/json' --data "{\"text\":\"${1}\"}" "${SLACK_WEBHOOK_URL}"
}
