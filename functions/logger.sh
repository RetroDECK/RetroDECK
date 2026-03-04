# This script provides a logging function 'log' that can be sourced in other scripts.
# It logs messages to both the terminal and a specified logfile, supporting multiple log levels.
# The log function takes three parameters: log level, log message, and optionally the logfile. If no logfile is specified, it writes to retrodeck/logs/retrodeck.log.
# 
# Supported logging levels (controlled by the variable 'rd_logging_level'):
# - none: No logs are produced.
# - info: Logs informational messages (i) and errors (e).
# - warn: Logs warnings (w), informational messages (i), and errors (e).
# - debug: Logs all message types (d, w, i, e).
#
# Type of log messages:
# - d: Debug message (logged only in debug level).
# - i: Informational message (logged in debug, info, and warn levels).
# - w: Warning message (logged in debug and warn levels).
# - e: Error message (logged in all levels except none).
#
# Example usage:
# log w "foo" -> Logs a warning with message "foo" to the default log file retrodeck/logs/retrodeck.log.
# log e "bar" -> Logs an error with message "bar" to the default log file retrodeck/logs/retrodeck.log.
# log i "baz" rekku.log -> Logs an informational message "baz" to the specified log file retrodeck/logs/rekku.log.
#
# The function auto-detects if the shell is sh and avoids colorizing the output in that case.

# Color and prefix exports for ES-DE
export logcolor_debug="\033[32m[DEBUG]"
export logcolor_error="\033[31m[ERROR]"
export logcolor_warn="\033[33m[WARN]"
export logcolor_info="\033[37m[INFO]"
export logcolor_default="\033[37m[LOG]"
export logprefix_debug="[DEBUG]"
export logprefix_error="[ERROR]"
export logprefix_warn="[WARN]"
export logprefix_info="[INFO]"
export logprefix_default="[LOG]"

# Log level numeric mapping
declare -A log_level_priority=( [none]=0 [error]=1 [warn]=2 [info]=3 [debug]=4 )
declare -A log_message_priority=( [e]=1 [w]=2 [i]=3 [d]=4 )

# Persistent file descriptor for the default log file
log_fd=""
log_fd_file=""

log_open_fd() {
  # Open a persistent file descriptor for the log file to avoid repeated open/close cycles.
  # USAGE: log_open_fd "$logfile"

  local logfile="$1"

  # Already open for this file
  if [[ "$log_fd" != "" && "$log_fd_file" == "$logfile" ]]; then
    return
  fi

  # Close existing fd if switching files
  if [[ "$log_fd" != "" ]]; then
    eval "exec $log_fd>&-" 2>/dev/null
  fi

  # Ensure directory and file exist
  local logdir
  logdir=$(dirname "$logfile")
  [[ ! -d "$logdir" ]] && mkdir -p "$logdir"

  log_fd=4
  log_fd_file="$logfile"
  eval "exec $log_fd>>\"$logfile\""
}

log() {
  # Log a message to the terminal and log file at the specified level.
  # USAGE: log $level "$message" ["$logfile"]

  local level="$1"
  local message="$2"
  local logfile="${3:-$rd_xdg_config_logs_path/retrodeck.log}"

  # Fast exit if logging is disabled or message level is below threshold
  local configured_priority=${log_level_priority[${rd_logging_level:-info}]:-3}
  [[ "$configured_priority" -eq 0 ]] && return
  local message_priority=${log_message_priority[$level]:-0}
  [[ "$message_priority" -eq 0 || "$message_priority" -gt "$configured_priority" ]] && return

  local timestamp
  printf -v timestamp '[%(%Y-%m-%d %H:%M:%S)T]' -1

  # Caller detection
  local caller="${FUNCNAME[1]:-FWORK}"
  caller="${caller^^}"

  # Select prefix and color based on level
  local prefix color
  case "$level" in
    d) prefix="[DEBUG]" color="\033[32m[DEBUG]" ;;
    e) prefix="[ERROR]" color="\033[31m[ERROR]" ;;
    w) prefix="[WARN]"  color="\033[33m[WARN]"  ;;
    i) prefix="[INFO]"  color="\033[37m[INFO]"  ;;
    *) prefix="[LOG]"   color="\033[37m[LOG]"   ;;
  esac

  # Terminal output
  if [[ "${LOG_SILENT:-false}" != "true" ]]; then
    echo -e "$color [$caller] $message\e[0m" >&2
  fi

  # File output via persistent fd
  log_open_fd "$logfile"
  echo "$timestamp $prefix [$caller] $message" >&$log_fd
}

rotate_logs() {
  # Rotate log files, compressing the current log and incrementing older archives.
  # USAGE: rotate_logs ["$logfile"]

  local logfile="${1:-$rd_xdg_config_logs_path/retrodeck.log}"
  local max_logs=3

  # Close the persistent fd before rotating
  if [[ "$log_fd" != "" && "$log_fd_file" == "$logfile" ]]; then
    eval "exec $log_fd>&-" 2>/dev/null
    log_fd=""
    log_fd_file=""
  fi

  for ((i=max_logs; i>0; i--)); do
    if [[ -f "${logfile}.${i}.tar.gz" ]]; then
      if (( i == max_logs )); then
        rm -f "${logfile}.${i}.tar.gz"
      else
        mv "${logfile}.${i}.tar.gz" "${logfile}.$((i+1)).tar.gz"
      fi
    fi
  done

  if [[ -f "$logfile" ]]; then
    tar -czf "${logfile}.1.tar.gz" -C "$(dirname "$logfile")" "$(basename "$logfile")" --remove-files &>/dev/null
  fi
}

log_close_fd() {
  # Close the persistent log file descriptor if open.
  # USAGE: log_close_fd

  if [[ "$log_fd" != "" ]]; then
    eval "exec $log_fd>&-" 2>/dev/null
    log_fd=""
    log_fd_file=""
  fi
}

register_cleanup log_close_fd
