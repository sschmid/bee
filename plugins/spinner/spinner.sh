#!/usr/bin/env bash
#
# Author: @sschmid
# Spinner as a loading indicator

SPINNER_TITLE=""
SPINNER_PID=0

spinner::_new() {
  echo "# spinner"
  echo "SPINNER_FRAMES=('-' '\' '|' '/')
SPINNER_INTERVAL=0.2"
}

start_spin() {
  while true; do
    for i in "${SPINNER_FRAMES[@]}"; do
      echo -ne "\r${SPINNER_TITLE} ${i}"
      sleep ${SPINNER_INTERVAL}
    done
  done
}

spinner_terminate() {
  local exit_code=$?
  if (( ${exit_code} != 0 )); then
    spinner::cancel
  fi
}

spinner::start() {
  tput civis
  stty -echo
  start_spin &
  SPINNER_PID=$!
}

spinner::stop() {
  if (( ${SPINNER_PID} != 0 )); then
    kill ${SPINNER_PID}
    SPINNER_PID=0
  fi
  echo -ne "\033[2K"
  "$@"
  stty echo
  tput cnorm
  echo ""
}

spinner::complete() {
  spinner::stop echo -ne "\r\033[0;32m${SPINNER_TITLE} ✔︎\033[0m"
}

spinner::cancel() {
  spinner::stop echo -ne "\r\033[0;31m${SPINNER_TITLE} ✗\033[0m"
}

spinner::wrap() {
  trap spinner::cancel INT TERM
  trap spinner_terminate EXIT

  SPINNER_TITLE="${1}"
  shift
  spinner::start
  "$@" &> /dev/null
  spinner::complete
}
