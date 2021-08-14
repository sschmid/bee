# bee::help
# job [-t | --time] <title> <command> ; run command as a job [show elapsed time]
# bee::help

BEE_JOB_SPINNER_INTERVAL=0.1
BEE_JOB_SPINNER_FRAMES=('🐝' ' 🐝' '  🐝' '   🐝' '    🐝' '     🐝' '      🐝' '       🐝' '        🐝' '         🐝' '        🐝' '       🐝' '      🐝' '     🐝' '    🐝' '   🐝' '  🐝' ' 🐝' '🐝')
BEE_JOB_SPINNER_PID=0
BEE_JOB_RUNNING=0
BEE_JOB_T=0
BEE_JOB_SHOW_TIME=0
BEE_JOB_TITLE=""
BEE_JOB_LOGFILE=""

bee::job() {
  if (($# >= 2)); then
    while (($#)); do case "$1" in
      -t | --time) BEE_JOB_SHOW_TIME=1 ;;
      --) shift; break ;;
      *) break ;;
    esac; shift; done

    bee::job::start "$@"
    bee::job::finish
  else
    bee::usage
  fi
}

bee::job::start() {
  BEE_JOB_TITLE="$1"
  shift
  bee::job::start_spinner
  if [[ -v BEE_RESOURCES ]]; then
    mkdir -p "${BEE_RESOURCES}/logs"
    BEE_JOB_LOGFILE="${BEE_RESOURCES}/logs/$(date -u '+%Y%m%d%H%M%S')-job-${BEE_JOB_TITLE// /-}-${RANDOM}${RANDOM}.log"
  else
    BEE_JOB_LOGFILE=/dev/null
  fi
  bee::run "$@" &> "${BEE_JOB_LOGFILE}"
}

bee::job::finish() {
  bee::job::stop_spinner
  if ((BEE_JOB_SHOW_TIME)); then
    echo -e "\r\033[2K\033[0;32m${BEE_JOB_TITLE} ✔︎ ($((SECONDS - BEE_JOB_T)) seconds)\033[0m"
  else
    echo -e "\r\033[2K\033[0;32m${BEE_JOB_TITLE} ✔︎\033[0m"
  fi
}

bee::job::start_spinner() {
  BEE_JOB_RUNNING=1
  BEE_JOB_T=${SECONDS}
  bee::add_int_trap bee::job::INT
  bee::add_exit_trap bee::job::EXIT
  if [[ -t 1 ]]; then
    tput civis &> /dev/null || true
    stty -echo
    bee::job::spin &
    BEE_JOB_SPINNER_PID=$!
  fi
}

bee::job::stop_spinner() {
  bee::remove_int_trap bee::job::INT
  bee::remove_exit_trap bee::job::EXIT
  if [[ -t 1 ]]; then
    if ((BEE_JOB_SPINNER_PID != 0)); then
      kill -9 ${BEE_JOB_SPINNER_PID} || true
      wait ${BEE_JOB_SPINNER_PID} &> /dev/null || true
      BEE_JOB_SPINNER_PID=0
    fi
    stty echo
    tput cnorm &> /dev/null || true
  fi
  BEE_JOB_RUNNING=0
}

bee::job::spin() {
  while true; do
    for i in "${BEE_JOB_SPINNER_FRAMES[@]}"; do
      if ((BEE_JOB_SHOW_TIME)); then
        echo -ne "\r\033[2K${BEE_JOB_TITLE} ($((SECONDS - BEE_JOB_T)) seconds) ${i}"
      else
        echo -ne "\r\033[2K${BEE_JOB_TITLE} ${i}"
      fi
      sleep ${BEE_JOB_SPINNER_INTERVAL}
    done
  done
}

bee::job::INT() {
  ((!BEE_JOB_RUNNING)) && return
  bee::job::stop_spinner
  if ((BEE_JOB_SHOW_TIME)); then
    echo "Aborted by $(whoami) ($((SECONDS - BEE_JOB_T)) seconds)" >> "${BEE_JOB_LOGFILE}"
  else
    echo "Aborted by $(whoami)" >> "${BEE_JOB_LOGFILE}"
  fi
}

bee::job::EXIT() {
  local -i status=$1
  ((!BEE_JOB_RUNNING)) && return
  if ((status)); then
    bee::job::stop_spinner
    if ((BEE_JOB_SHOW_TIME)); then
      echo -e "\r\033[2K\033[0;31m${BEE_JOB_TITLE} ✗ ($((SECONDS - BEE_JOB_T)) seconds)\033[0m"
    else
      echo -e "\r\033[2K\033[0;31m${BEE_JOB_TITLE} ✗\033[0m"
    fi
  fi
}
