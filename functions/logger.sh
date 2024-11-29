# This script provides a logging function 'log' that can be sourced in other scripts.
# It logs messages to both the terminal and a specified logfile, supporting multiple log levels.
# The log function takes three parameters: log level, log message, and optionally the logfile. If no logfile is specified, it writes to retrodeck/logs/retrodeck.log.
# 
# Supported logging levels (controlled by the variable 'logging_level'):
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
  # Exit early if logging_level is "none"
  if [[ $logging_level == "none" ]]; then
    return
  fi

  local level="$1"  # Logging level of the current message
  local message="$2"  # Message to log
  local logfile="${3:-$rd_logs_folder/retrodeck.log}"  # Log file, default to retrodeck.log
  local timestamp="$(date +[%Y-%m-%d\ %H:%M:%S.%3N])"  # Timestamp for the log entry
  local colorize_terminal=true

  # Determine the calling function or use [FWORK]
  local caller="${FUNCNAME[1]:-[FWORK]}"
  caller="${caller^^}" # Convert to uppercase

  # Check if the shell is sh (not bash or zsh) to avoid colorization
  if [ "${SHELL##*/}" = "sh" ]; then
    colorize_terminal=false
  fi

  # Function to check if the current message level should be logged
  should_log() {
    case "$logging_level" in
      debug) return 0 ;;  # Always log everything
      info) [[ "$level" == "i" || "$level" == "e" ]] && return 0 ;;
      warn) [[ "$level" != "d" ]] && return 0 ;;
      error) [[ "$level" == "e" ]] && return 0 ;;
    esac
    return 1
  }

  if should_log; then
    # Define message colors based on level
    case "$level" in
      d)
        color="\e[32m[DEBUG]"
        prefix="[DEBUG]"
        ;;
      e)
        color="\e[31m[ERROR]"
        prefix="[ERROR]"
        ;;
      w)
        color="\e[33m[WARN]"
        prefix="[WARN]"
        ;;
      i)
        color="\e[34m[INFO]"
        prefix="[INFO]"
        ;;
      *)
        color="\e[37m[LOG]"
        prefix="[LOG]"
        ;;
    esac

    # Construct the log message
    if [ "$colorize_terminal" = true ]; then
      colored_message="$color [$caller] $message\e[0m"
    else
      colored_message="$timestamp $prefix [$caller] $message"
    fi
    log_message="$timestamp $prefix [$caller] $message"

    # Display the message in the terminal
    echo -e "$colored_message" >&2

    # Write the log message to the log file
    if [ ! -f "$logfile" ]; then
      echo "$timestamp [WARN] Log file not found in \"$logfile\", creating it" >&2
      touch "$logfile"
    fi
    echo "$log_message" >> "$logfile"
  fi
}
