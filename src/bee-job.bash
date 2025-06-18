########################################
# Run plugin or commands as a job
# Arguments:
#   [--logfile] [--time] title command [arguments]
########################################
declare -ig job_log_to_file=0
declare -ig job_show_time=0
declare -ig job_is_running=0
declare -ig job_time=0
declare -ig spinner_pid=0

job_spinner_interval=0.1
job_spinner_frames=(
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

bee::job::spin() {
  while :; do
    for i in "${job_spinner_frames[@]}"; do
      echo -ne "${BEE_LINE_RESET}${job_title}$(bee::job::duration) ${i}"
      sleep ${job_spinner_interval}
    done
  done
}

bee::job::stop_spinner() {
  bee::remove_int_trap bee::job::INT
  bee::remove_exit_trap bee::job::EXIT
  if [[ -t 1 ]]; then
    if (( spinner_pid != 0 )); then
      kill -9 ${spinner_pid} || true
      wait ${spinner_pid} &>/dev/null || true
      spinner_pid=0
    fi
    stty echo
    tput cnorm &>/dev/null || true
  fi
  job_is_running=0
}

bee::job::duration() {
  (( ! job_show_time )) || echo " ($(( SECONDS - job_time )) seconds)"
}

bee::job::INT() {
  (( job_is_running )) || return 0
  bee::job::stop_spinner
  echo "Aborted by $(whoami)$(bee::job::duration)" >>"${job_logfile}"
}

bee::job::EXIT() {
  local -i status=$1
  (( job_is_running )) || return 0
  if (( status )); then
    bee::job::stop_spinner
    echo -e "${BEE_LINE_RESET}${BEE_COLOR_FAIL}${job_title} ${BEE_CHECK_FAIL}$(bee::job::duration)${BEE_COLOR_RESET}"
  fi
}

main() {
  while (( $# )); do
    case "$1" in
      --logfile) job_log_to_file=1; shift ;;
      --time) job_show_time=1; shift ;;
      --) shift; break ;;
      *) break ;;
    esac
  done

  if (( $# < 2 )); then
    bee::source "bee-help"
    exit 1
  fi

  # Setup job
  job_title="$1"; shift
  if (( job_log_to_file )); then
    mkdir -p "${BEE_RESOURCES}/logs"
    job_logfile="${BEE_RESOURCES}/logs/$(date -u '+%Y%m%d%H%M%S')-job-${job_title// /-}-${RANDOM}${RANDOM}.log"
  else
    job_logfile=/dev/null
  fi

  if (( BEE_VERBOSE )); then
    # Run job without spinner
    echo "${job_title}"
    bee::main "$@" 2>&1 | tee "${job_logfile}"
  else
    # Run job with spinner
    job_is_running=1
    job_time=${SECONDS}
    bee::add_int_trap bee::job::INT
    bee::add_exit_trap bee::job::EXIT
    if [[ -t 1 ]]; then
      tput civis &>/dev/null || true
      stty -echo
      bee::job::spin &
      spinner_pid=$!
    fi

    bee::main "$@" &>"${job_logfile}"
  fi

  # Finish job
  bee::job::stop_spinner
  (( ! BEE_VERBOSE )) && line_reset="${BEE_LINE_RESET}" || line_reset=""
  echo -e "${line_reset}${BEE_COLOR_SUCCESS}${job_title} ${BEE_CHECK_SUCCESS}$(bee::job::duration)${BEE_COLOR_RESET}"
}

main "$@"
