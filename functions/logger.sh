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

log() {

  # Define and export log color environment variables for ES-DE
  export logcolor_debug="\033[32m[DEBUG]"
  export logcolor_error="\033[31m[ERROR]"
  export logcolor_warn="\033[33m[WARN]"
  export logcolor_info="\033[37m[INFO]"
  export logcolor_default="\033[37m[LOG]"

  # Define and export log prefix environment variables for ES-DE
  export logprefix_debug="[DEBUG]"
  export logprefix_error="[ERROR]"
  export logprefix_warn="[WARN]"
  export logprefix_info="[INFO]"
  export logprefix_default="[LOG]"

  # Exit immediately if rd_logging_level is "none"
  if [[ $rd_logging_level == "none" ]]; then
    return
  fi

  local level="$1"          # Current message level
  local message="$2"        # Message to log
  local logfile="${3:-$rd_xdg_config_logs_path/retrodeck.log}"  # Default log file
  local timestamp="$(date +[%Y-%m-%d\ %H:%M:%S.%3N])"   # Timestamp
  local colorize_terminal=true

  # Determine the calling function, or use [FWORK]
  local caller="${FUNCNAME[1]:-FWORK}"
  caller="${caller^^}"  # Convert to uppercase

  # # Check if the shell is sh to avoid colorization
  # if [ "${SHELL##*/}" = "sh" ]; then
  #   colorize_terminal=false
  # fi

  # Internal function to check if the message should be logged
  should_log() {
    case "$rd_logging_level" in
      debug) return 0 ;;  # Log everything
      info) [[ "$level" == "i" || "$level" == "e" ]] && return 0 ;;
      warn) [[ "$level" != "d" ]] && return 0 ;;
      error) [[ "$level" == "e" ]] && return 0 ;;
    esac
    return 1
  }

  if should_log; then
    # Define colors based on the message level
    case "$level" in
      d)
        color="${logcolor_debug:-\033[32m[DEBUG]}"
        prefix="${logprefix_debug:-[DEBUG]}"
        ;;
      e)
        color="${logcolor_error:-\033[31m[ERROR]}"
        prefix="${logprefix_error:-[ERROR]}"
        ;;
      w)
        color="${logcolor_warn:-\033[33m[WARN]}"
        prefix="${logprefix_warn:-[WARN]}"
        ;;
      i)
        color="${logcolor_info:-\033[37m[INFO]}"
        prefix="${logprefix_info:-[INFO]}"
        ;;
      *)
        color="${logcolor_default:-\033[37m[LOG]}"
        prefix="${logprefix_default:-[LOG]}"
        ;;
    esac

    # Build the message to display
    if [ "$colorize_terminal" = true ]; then
      colored_message="$color [$caller] $message\e[0m"
    else
      colored_message="$timestamp $prefix [$caller] $message"
    fi
    log_message="$timestamp $prefix [$caller] $message"

    # If silent mode is not active, print the message to the terminal
    if [[ "$LOG_SILENT" != "true" ]]; then
      echo -e "$colored_message" >&2
    fi

    # Ensure the log file exists
    if [ ! -f "$logfile" ]; then
      if [[ ! -d "$(dirname "$logfile")" ]]; then
        mkdir -p "$(dirname "$logfile")"
      fi
      touch "$logfile"
    fi

    # Write the log to the file
    echo "$log_message" >> "$logfile"
  fi
}


# The rotate_logs function manages log file rotation to limit the number of logs retained.
# It compresses the current log file into a .tar.gz archive, increments the version of 
# older log files (e.g., retrodeck.1.tar.gz to retrodeck.2.tar.gz), and deletes the oldest 
# archive if it exceeds the maximum limit (default: 3 rotated logs). After rotation, 
# the original log file is cleared for continued logging.

rotate_logs() {
  local logfile="${1:-$rd_xdg_config_logs_path/retrodeck.log}"  # Default log file
  local max_logs=3  # Maximum number of rotated logs to keep

  # Rotate existing logs
  for ((i=max_logs; i>0; i--)); do
    if [[ -f "${logfile}.${i}.tar.gz" ]]; then
      if (( i == max_logs )); then
        # Remove the oldest log if it exceeds the limit
        rm -f "${logfile}.${i}.tar.gz"
      else
        # Rename log file to the next number
        mv "${logfile}.${i}.tar.gz" "${logfile}.$((i+1)).tar.gz"
      fi
    fi
  done

  # Compress the current log file if it exists
  if [[ -f "$logfile" ]]; then
    # Compress without directory structure and suppress tar output
    tar -czf "${logfile}.1.tar.gz" -C "$(dirname "$logfile")" "$(basename "$logfile")" --remove-files &>/dev/null
  fi
}
