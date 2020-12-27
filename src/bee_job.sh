#!/usr/bin/env bash

BEE_SPINNER_FRAMES=(
  '🐝'
  ' 🐝'
  '  🐝'
  '   🐝'
  '    🐝'
  '     🐝'
  '      🐝'
  '       🐝'
  '        🐝'
  '         🐝'
  '        🐝'
  '       🐝'
  '      🐝'
  '     🐝'
  '    🐝'
  '   🐝'
  '  🐝'
  ' 🐝'
  '🐝'
)
BEE_SPINNER_INTERVAL=0.1

BEE_SPINNER_PID=0
BEE_JOB_RUNNING=false
BEE_JOB_TITLE=""
BEE_JOB_LOGFILE=""

bee_spinner() {
  while true; do
    for i in "${BEE_SPINNER_FRAMES[@]}"; do
      echo -ne "\r\033[2K${BEE_JOB_TITLE} ${i}"
      sleep ${BEE_SPINNER_INTERVAL}
    done
  done
}

start_spinner() {
  tput civis
  stty -echo
  bee_spinner &
  BEE_SPINNER_PID=$!
}

stop_spinner() {
  if (( ${BEE_SPINNER_PID} != 0 )); then
    kill ${BEE_SPINNER_PID} || true
    BEE_SPINNER_PID=0
  fi
  if [[ -t 1 ]]; then
    stty echo
    tput cnorm
  fi
}

complete_job() {
  stop_spinner
  echo -e "\r\033[2K\033[0;32m${BEE_JOB_TITLE} ✔︎\033[0m"
}

job_builtin_help=("job <title> <command>| run a command as a job")
job() {
  BEE_JOB_RUNNING=true
  BEE_JOB_TITLE="${1}"
  shift
  start_spinner
  BEE_JOB_LOGFILE="${BEE_RESOURCES}/logs/$(date -u '+%Y-%m-%d-%H-%M-%S')-job-${BEE_JOB_TITLE}-$(uuidgen).log"
  mkdir -p "${BEE_RESOURCES}/logs"
  "$@" &> "${BEE_JOB_LOGFILE}"
  complete_job
  BEE_JOB_RUNNING=false
}

job_int() {
  stop_spinner
  echo "Aborted by $(whoami)" >> "${BEE_JOB_LOGFILE}"
}

job_term() {
  stop_spinner
  echo "Terminated" >> "${BEE_JOB_LOGFILE}"
}

job_exit() {
  local exit_code=$1
  if (( ${exit_code} != 0 )); then
    stop_spinner
    echo -e "\r\033[2K\033[0;31m${BEE_JOB_TITLE} ✗\033[0m"
  fi
}
