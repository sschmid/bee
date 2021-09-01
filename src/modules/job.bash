# bee::help
# job [-t | --time] <title> <command> : run command as a job [show elapsed --time]
# bee::help

BEE_JOB_SPINNER_INTERVAL=0.1
BEE_JOB_SPINNER_FRAMES=('🐝' ' 🐝' '  🐝' '   🐝' '    🐝' '     🐝' '      🐝' '       🐝' '        🐝' '         🐝' '        🐝' '       🐝' '      🐝' '     🐝' '    🐝' '   🐝' '  🐝' ' 🐝' '🐝')
declare -ig BEE_JOB_SPINNER_PID=0
declare -ig BEE_JOB_RUNNING=0
declare -ig BEE_JOB_T=0
declare -ig BEE_JOB_SHOW_TIME=0
BEE_JOB_TITLE=""
BEE_JOB_LOGFILE=""

bee::job::comp() {
  if ((!$#)); then
    echo "-t --time"
  fi
}

bee::job() {
  if (($# >= 2)); then
    while (($#)); do case "$1" in
      -t | --time) BEE_JOB_SHOW_TIME=1; shift ;;
      --) shift; break ;; *) break ;;
    esac done

    bee::job::start "$@"
    bee::job::finish
  else
    bee::usage
  fi
}

bee::job::start() {
  BEE_JOB_TITLE="$1"; shift
  if [[ -v BEE_RESOURCES ]]; then
    mkdir -p "${BEE_RESOURCES}/logs"
    BEE_JOB_LOGFILE="${BEE_RESOURCES}/logs/$(date -u '+%Y%m%d%H%M%S')-job-${BEE_JOB_TITLE// /-}-${RANDOM}${RANDOM}.log"
  else
    BEE_JOB_LOGFILE=/dev/null
  fi

  if ((BEE_VERBOSE)); then
    echo "${BEE_JOB_TITLE}"
    bee::run "$@" 2>&1 | tee "${BEE_JOB_LOGFILE}"
  else
    bee::job::start_spinner
    bee::run "$@" &> "${BEE_JOB_LOGFILE}"
  fi
}

bee::job::finish() {
  bee::job::stop_spinner
  local line_reset
  ((!BEE_VERBOSE)) && line_reset="\r\033[2K" || line_reset=""
  echo -e "${line_reset}${BEE_COLOR_SUCCESS}${BEE_JOB_TITLE} ${BEE_CHECK_SUCCESS}$(bee::job::duration)${BEE_COLOR_RESET}"
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
      echo -ne "\r\033[2K${BEE_JOB_TITLE}$(bee::job::duration) ${i}"
      sleep ${BEE_JOB_SPINNER_INTERVAL}
    done
  done
}

bee::job::INT() {
  ((!BEE_JOB_RUNNING)) && return
  bee::job::stop_spinner
  echo "Aborted by $(whoami)$(bee::job::duration)" >> "${BEE_JOB_LOGFILE}"
}

bee::job::EXIT() {
  local -i status=$1
  ((!BEE_JOB_RUNNING)) && return
  if ((status)); then
    bee::job::stop_spinner
    echo -e "\r\033[2K${BEE_COLOR_FAIL}${BEE_JOB_TITLE} ${BEE_CHECK_FAIL}$(bee::job::duration)${BEE_COLOR_RESET}"
  fi
}

bee::job::duration() {
  if ((BEE_JOB_SHOW_TIME)); then
    echo " ($((SECONDS - BEE_JOB_T)) seconds)"
  fi
}
